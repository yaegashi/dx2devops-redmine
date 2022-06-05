require 'fileutils'

class RMOps::CLI
  desc 'setup', "Set up Redmine instance"
  def setup
    RMOps::Tasks.create_symlinks
    RMOps::Tasks.migrate_database
    unless RMOps::Tasks.default_admin_account_changed?
      login = 'admin'
      pass = RMOps::Tasks.reset_passwd(login)
      logger.info "Reset password for user #{login.inspect}"
      logger.info "New password: #{pass.inspect}"
    end
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
