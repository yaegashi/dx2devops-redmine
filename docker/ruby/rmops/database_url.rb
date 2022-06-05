require 'erb'
require 'uri'
require 'cgi'

class RMOps::DatabaseURL
  TEMPLATES_DIR = File.expand_path('templates', __dir__)
  DBSpec = Struct.new(:type, :user, :pass, :host, :port, :name, :params, :ssl)

  attr_reader :uri, :db, :templates_dir

  def initialize(url, path = TEMPLATES_DIR)
    @uri = URI.parse(url)
    @db = DBSpec.new
    @db.type = @uri.scheme
    @db.user = CGI.unescape(@uri.user)
    @db.pass = CGI.unescape(@uri.password)
    @db.host = @uri.host
    @db.port = @uri.port
    @db.name = @uri.path[1..]
    @db.params = URI.decode_www_form(@uri.query.to_s).to_h
    case @db.type
    when 'mysql2'
      @db.ssl = !@db.params.keys.grep(/^ssl/).empty?
    when 'postgresql'
      @db.ssl = %w[require verify-ca verify-full].include?(@db.params['sslmode'])
    else
      raise "Unsupported database type: '#{db.type}'"
    end
    if @db.host =~ /\.database\.azure\.com$/
      # For Azure database products, the user name in SQL should be without '@host'
      @db.user.sub!(/@[^@]*$/, '')
    end
    @templates_dir = path
  end

  def generate_sql
    src = File.join(templates_dir, "database-#{db.type}.sql.erb")
    erb = ERB.new(File.read(src), trim_mode: '-')
    erb.filename = src
    erb.result(binding)
  end
end
