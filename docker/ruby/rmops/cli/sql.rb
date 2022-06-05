class RMOps::CLI
  desc 'sql', 'Generate SQL to initialize database'
  def sql(url = DATABASE_URL)
    raise 'No DATABASE_URL specified' if url.to_s.empty?

    dburl = RMOps::DatabaseURL.new(url)
    puts dburl.generate_sql
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
