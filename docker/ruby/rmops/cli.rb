require 'thor'

class RMOps::CLI < Thor
  include RMOps::Consts
  include RMOps::Logger

  def self.exit_on_failure?
    true
  end
end

require_relative 'cli/setup'
require_relative 'cli/passwd'
require_relative 'cli/sql'
require_relative 'cli/entrypoint'
require_relative 'cli/dump'
require_relative 'cli/restore'
