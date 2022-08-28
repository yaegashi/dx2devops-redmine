class RMOps::CLI
  desc 'dump', 'Dump site to backup'
  def dump(name)
    raise 'No backup specified' if name.to_s.empty?

    RMOps::Tasks.dump(name)
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
