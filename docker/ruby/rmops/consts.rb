module RMOps::Consts
  def self.make_bool(str)
    case str.to_s.strip.downcase
    when 'true', 'yes', 'on', 't', 'y', '1'
      true
    else
      false
    end
  end

  REDMINE_DIR = ENV['REDMINE_DIR'] || '/redmine'
  WWWROOT_DIR = ENV['WWWROOT_DIR'] || '/home/site/wwwroot'
  STATICSITE_DIR = File.join(WWWROOT_DIR, 'staticsite')
  BACKUPS_DIR = File.join(WWWROOT_DIR, 'backups')
  FILES_DIR = File.join(WWWROOT_DIR, 'files')
  CONFIG_DIR = File.join(WWWROOT_DIR, 'config')
  PLUGINS_DIR = File.join(WWWROOT_DIR, 'plugins')
  PUBLIC_DIR = File.join(WWWROOT_DIR, 'public')
  PUBLIC_THEMES_DIR = File.join(WWWROOT_DIR, 'public/themes')
  PUBLIC_PLUGIN_ASSETS_DIR = File.join(WWWROOT_DIR, 'public/plugin_assets')
  DATABASE_URL = ENV['DATABASE_URL']
  DATABASE_FLEXIBLE = make_bool(ENV['DATABASE_FLEXIBLE'])
  RAILS_IN_SERVICE = make_bool(ENV['RAILS_IN_SERVICE'])
  WHOAMI_DEBUG = make_bool(ENV['WHOAMI_DEBUG'])
end
