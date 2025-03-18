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

  def self.hosts
    p Dir.each_child(base_dir).to_a
    Dir.each_child(base_dir).map &Host.method(:new)
  end

end
