require "logger"

module Logging
  def logger
    @@logger
  end
  def self.logger
    @@logger
  end
  @@logger = Logger.new $stderr
  @@logger.info! if ENV["APP_ENV"] == "production" || ENV["RACK_ENV"] == "production"

  default_formatter = logger.formatter || Logger::Formatter.new
  @@logger.formatter = proc { |severity, time, progname, msg|
    # set the caller as progname
    progname = caller[3] if Logger::Severity.coerce(severity) >= Logger::ERROR
    default_formatter.call(severity, time, progname, msg)
  }
end
