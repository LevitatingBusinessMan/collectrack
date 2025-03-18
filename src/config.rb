require './src/rrd.rb'

class Config
  def self.init
    puts "imagine me loading a config"
    @@base_dir = "/var/lib/collectd"
    self.freeze
  end

  def self.base_dir
    @@base_dir
  end

  def self.hosts
    Dir.each_child(@@base_dir).map &Host.method(:new)
  end

end
