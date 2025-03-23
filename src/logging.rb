require "logger"
$log = Logger.new $stdout
$log.level = :info if ENV["APP_ENV"] == "production" || ENV["RACK_ENV"] == "production"
