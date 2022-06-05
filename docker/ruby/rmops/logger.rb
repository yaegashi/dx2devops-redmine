require 'logger'

module RMOps::Logger
  def logger
    @@logger ||= Logger.new(STDOUT)
  end
end
