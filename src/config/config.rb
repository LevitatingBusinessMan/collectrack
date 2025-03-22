require_relative "scanner.rex"
require_relative "parser.tab"
require "./src/collectd"

class Option
  attr_reader :identifier, :arguments
  def initialize identifier, arguments
    @identifier = identifier
    @arguments = arguments
  end

  def to_s
    "#{@identifier} #{@arguments.join(", ")}"
  end

end

class Block
  attr_reader :identifier, :statements, :arguments
  def initialize identifier, arguments, statements
    @identifier = identifier
    @arguments = arguments
    @statements = statements
  end

  def [] key, argument=nil
    key = key.to_s.split('_').collect(&:capitalize).join
    argument = argument.to_s if argument
    @statements.find {
      if argument
        it.identifier == key and it.arguments.first == argument
      else
        it.identifier == key
      end
    }
  end

end

class Config
  def self.load file
    @@parser = CollectdConfigParser.new
    @@statements = @@parser.scan_file file
  end


  #find a statement using the identifier and optional first argument
  def self.[] key, argument=nil
    key = key.to_s.split('_').collect(&:capitalize).join
    argument = argument.to_s if argument
    @@statements.find {
      if argument
        it.identifier == key and it.arguments.first == argument
      else
        it.identifier == key
      end
    }
  end

  def self.hosts
    Dir.each_child(base_dir).map(&Host.method(:new))
  end

  def self.unixsock
    self[:plugin, :unixsock]&.[](:socket_file)&.arguments.first
  end

  def self.base_dir
    self[:base_dir]&.arguments&.first || "/var/lib/collectd"
  end

  def self.plugin_config_dir
    self[:collect_track]&.[](:plugin_config_dir)&.arguments&.first || "./plugins"
  end

  def self.interval
    self[:interval]&.arguments&.first&.to_i || 10
  end

end
