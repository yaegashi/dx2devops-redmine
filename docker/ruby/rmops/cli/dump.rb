class RMOps::CLI
  desc 'dump', 'Dump database to a file'
  def dump(path)
    raise 'No path specified' if path.to_s.empty?

    dburl = RMOps::DatabaseURL.new(DATABASE_URL)
    args = dburl.generate_dump
    logger.info "Dumping database to #{path.inspect}"
    logger.info "Running #{args.inspect}"
    system(dburl.env, args[0], *args[1..], exception: true, out: path)
  rescue StandardError => e
    logger.fatal e.to_s
    exit 1
  end
end
