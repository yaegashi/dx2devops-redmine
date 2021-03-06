module RMOps::Tasks
  extend RMOps::Tasks
  include RMOps::Consts
  include RMOps::Utils

  def self.create_symlinks
    enter_dir do
      rmtree(['files', 'public/plugin_assets'])
      makedirs([FILES_DIR, PUBLIC_PLUGIN_ASSETS_DIR])
      symlink(FILES_DIR, './files', force: true)
      symlink(PUBLIC_PLUGIN_ASSETS_DIR, './public/plugin_assets', force: true)
      Dir.glob(File.join(PLUGINS_DIR, '*')).each do |path|
        symlink(path, 'plugins', force: true) if File.directory?(path)
      end
      Dir.glob(File.join(PUBLIC_THEMES_DIR, '*')).each do |path|
        symlink(path, 'public/themes', force: true) if File.directory?(path)
      end
      Dir.glob(File.join(CONFIG_DIR, '*')).each do |path|
        symlink(path, 'config', force: true) if File.file?(path)
      end
    end
  end

  def migrate_database
    enter_dir do
      run 'rake db:migrate'
      run 'rake redmine:plugins:migrate'
    end
  end

  def default_admin_account_changed?
    enter_redmine(quiet: true) do
      User.default_admin_account_changed?
    end
  end

  def reset_passwd(login)
    enter_redmine do
      u = User.find_by(login: login)
      raise "User not found: #{login}" if u.nil?

      pass = pwgen
      u.password = pass
      u.password_confirmation = pass
      u.must_change_passwd = true
      u.save!
      pass
    end
  end

  def initialize_secret_key_base
    enter_dir do
      if ENV['SECRET_KEY_BASE'].nil?
        logger.warn 'Initialize SECRET_KEY_BASE variable'
        require 'securerandom'
        ENV['SECRET_KEY_BASE'] = SecureRandom.hex(64)
      end
    end
  end

  def initialize_database_config
    logger.info 'Initialize config/database.yml'
    enter_dir do
      if DATABASE_URL and !File.exist?('config/database.yml')
        dburl = RMOps::DatabaseURL.new(DATABASE_URL)
        File.open('config/database.yml', 'w') do |file|
          file.puts %({"0":{"adapter":"#{dburl.db.type}"}})
        end
      end
    end
  end

  def start_openssh_server
    logger.info 'Initialize /root/.ssh/environment'
    Dir.mkdir('/root/.ssh', 0o700) unless File.exist?('/root/.ssh')
    File.open('/root/.ssh/environment', 'w') do |file|
      ENV.each do |k, v|
        file.puts "#{k}=#{v}"
      end
    end
    logger.info 'Start OpenSSH server'
    run '/usr/sbin/sshd'
  rescue StandardError => e
    logger.error e.to_s
    logger.warn 'Skip OpenSSH server'
  end

  def start_rails_server
    logger.info "RAILS_IN_SERVICE is #{RAILS_IN_SERVICE}"
    if RAILS_IN_SERVICE
      enter_dir do
        File.unlink('tmp/pid/server.pid') if File.exist?('tmp/pid/server.pid')
        run 'rails server -b 0.0.0.0 -p 8080'
      end
    else
      index_file = File.join(STATICSITE_DIR, 'index.html')
      unless File.exist?(index_file)
        makedirs(STATICSITE_DIR)
        File.open(index_file, 'w') do |file|
          file.puts 'Maintenance mode'
        end
      end
      run "ruby -run -e httpd #{STATICSITE_DIR} -p 8080"
    end
  end
end
