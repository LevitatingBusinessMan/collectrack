require "logger"
$log = Logger.new $stderr
$log.level = :info if ENV["APP_ENV"] == "development"
