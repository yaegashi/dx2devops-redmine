class RMOps::CLI
  desc 'entrypoint', 'Container entrypoint'
  def entrypoint
    raise 'Not an entrypoint process (PID != 1)' if Process.pid != 1

    RMOps::Tasks.create_symlinks
    RMOps::Tasks.initialize_secret_key_base
    RMOps::Tasks.initialize_database_config
    RMOps::Tasks.start_openssh_server
    RMOps::Tasks.start_rails_server
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
