require 'erb'
require 'uri'
require 'cgi'
require 'tempfile'

class RMOps::DatabaseURL
  TEMPLATES_DIR = File.expand_path('templates', __dir__)
  DBSpec = Struct.new(:type, :uri_user, :user, :pass, :host, :port, :name, :params, :ssl, :env)

  attr_reader :uri, :db, :templates_dir

  def initialize(url, **opts)
    opts = { templates_dir: TEMPLATES_DIR }.merge(opts)
    @uri = URI.parse(url)
    @db = DBSpec.new
    @db.type = opts[:type] || @uri.scheme
    @db.user = @db.uri_user = opts[:user] || CGI.unescape(@uri.user)
    @db.pass = opts[:pass] || CGI.unescape(@uri.password)
    @db.host = opts[:host] || @uri.host
    @db.port = opts[:port] || @uri.port
    @db.name = opts[:name] || @uri.path[1..]
    @db.params = opts[:params] || URI.decode_www_form(@uri.query.to_s).to_h
    @db.env = {}
    if @db.host =~ /\.database\.azure\.com$/
      # For Azure database products, the user name in SQL should be without '@host'
      @db.user.sub!(/@[^@]*$/, '')
    end
    case @db.type
    when 'mysql2'
      @db.ssl = !@db.params.keys.grep(/^ssl/).empty?
      @db.port ||= 3306
      @db.env['MYSQL_PWD'] = @db.pass unless @db.pass.to_s.empty?
    when 'postgresql'
      @db.ssl = %w[require verify-ca verify-full].include?(@db.params['sslmode'])
      @db.port ||= 5432
      @db.env['PGPASSWORD'] = @db.pass unless @db.pass.to_s.empty?
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
