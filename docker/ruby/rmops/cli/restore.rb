class RMOps::CLI
  desc 'restore', 'Restore site from backup'
  def restore(name)
    raise 'No backup specified' if name.to_s.empty?

    RMOps::Tasks.restore(name)
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
