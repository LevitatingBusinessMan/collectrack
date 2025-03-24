require "logger"

module Logging
  def logger
    @@logger
  end
  @@logger = Logger.new $stdout
  @@logger.level = :info if ENV["APP_ENV"] == "production" || ENV["RACK_ENV"] == "production"
end
