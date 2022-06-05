class RMOps::CLI
  desc 'passwd', 'Reset user password'
  def passwd(login)
    pass = RMOps::Tasks.reset_passwd(login)
    logger.info "Reset password for user #{login.inspect}"
    logger.info "New password: #{pass.inspect}"
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
