require './src/collectd.rb'
require 'tomlrb'

class Config
  def self.init
    @@toml = Tomlrb.load_file('config.toml', symbolize_keys: true)
    self.freeze
  end

  def self.base_dir
    @@toml[:base_dir]
  end

  def self.plugin_config_dir
    @@toml[:plugin_config_dir]
  end

  def self.hosts
    Dir.each_child(base_dir).map &Host.method(:new)
  end

end
