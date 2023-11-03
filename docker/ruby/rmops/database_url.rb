require 'erb'
require 'uri'
require 'cgi'
require 'tempfile'

class RMOps::DatabaseURL
  TEMPLATES_DIR = File.expand_path('templates', __dir__)
  DBSpec = Struct.new(:type, :uri_user, :user, :pass, :host, :port, :name, :params, :ssl, :flexible, :env)

  attr_reader :uri, :db, :templates_dir

  def initialize(url, **opts)
    opts = { templates_dir: TEMPLATES_DIR }.merge(opts)
    @uri = URI.parse(url)
    @db = DBSpec.new
    @db.type = opts[:type] || @uri.scheme
    @db.user = @db.uri_user = opts[:user] || CGI.unescape(@uri.user.to_s)
    @db.pass = opts[:pass] || CGI.unescape(@uri.password.to_s)
    @db.host = opts[:host] || @uri.host
    @db.port = opts[:port] || @uri.port
    @db.name = opts[:name] || @uri.path[1..]
    @db.params = opts[:params] || URI.decode_www_form(@uri.query.to_s).to_h
    @db.flexible = opts.fetch(:flexible, RMOps::Consts::DATABASE_FLEXIBLE)
    @db.env = {}
    if !@db.flexible && @db.host =~ /\.database\.azure\.com$/
      # Fix user name for Azure database single server products
      suffix = "@#{@db.host.sub(/\..*/, '')}"
      @db.user = @db.user.delete_suffix(suffix)
      @db.uri_user += suffix unless @db.uri_user.end_with?(suffix)
    end
    case @db.type
    when 'sqlite3'
    when 'mysql2'
      @db.ssl = !@db.params.keys.grep(/^ssl/).empty?
      @db.port ||= 3306
      @db.env['MYSQL_PWD'] = @db.pass unless @db.pass.to_s.empty?
    when 'postgresql'
      @db.ssl = %w[require verify-ca verify-full].include?(@db.params['sslmode'])
      @db.port ||= 5432
      @db.env['PGPASSWORD'] = @db.pass unless @db.pass.to_s.empty?
      @db.env['PGSSLMODE'] = @db.params['sslmode'] if @db.ssl
    else
      raise "Unsupported database type: '#{db.type}'"
    end
    @templates_dir = opts[:templates_dir]
  end

  def env
    @db.env.map { |k, v| [k.to_s, v.to_s] }.to_h
  end

  def generate(name)
    src = File.join(templates_dir, name)
    erb = ERB.new(File.read(src), trim_mode: '-')
    erb.filename = src
    erb.result(binding)
  end

  def generate_dbsql
    generate("dbsql-#{db.type}.sql.erb")
  end

  def generate_cliuser
    generate("cliuser-#{db.type}.args.erb").split
  end

  def generate_cliadmin
    generate("cliadmin-#{db.type}.args.erb").split
  end

  def generate_dump
    generate("dump-#{db.type}.args.erb").split
  end

  def generate_restore
    generate("restore-#{db.type}.args.erb").split
  end
end
