class RMOps::CLI
  desc 'dbinit', 'Initialize database'
  def dbinit(url = DATABASE_URL)
    raise 'No DATABASE_URL specified' if url.to_s.empty?

    RMOps::Tasks.dbinit(url)
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
