require "./src/config/config"
require_relative "helpers"

Config.load

puts "Hosts:"
host = Config.hosts.choose

puts "Plugins:"
plugin = host.plugins.choose

puts "Instances:"
instance = plugin.instances.choose


