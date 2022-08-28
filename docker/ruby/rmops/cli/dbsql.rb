class RMOps::CLI
  desc 'dbsql', 'Generate SQL for initialization'
  def dbsql(url = DATABASE_URL)
    raise 'No DATABASE_URL specified' if url.to_s.empty?

    dburl = RMOps::DatabaseURL.new(url)
    puts dburl.generate_dbsql
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
