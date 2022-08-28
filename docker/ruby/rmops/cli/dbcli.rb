class RMOps::CLI
  desc 'dbcli', 'Launch DB client'
  def dbcli(url = DATABASE_URL)
    raise 'No DATABASE_URL specified' if url.to_s.empty?

    RMOps::Tasks.dbcli(url)
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
