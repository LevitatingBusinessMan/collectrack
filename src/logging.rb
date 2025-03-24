require "logger"

module Logging
  def logger
    @@logger
  end
  def self.logger
    @@logger
  end
  @@logger = Logger.new $stderr
  @@logger.level = :info if ENV["APP_ENV"] == "production" || ENV["RACK_ENV"] == "production"
end
