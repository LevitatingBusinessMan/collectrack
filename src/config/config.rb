require_relative "scanner.rex"
require_relative "parser.tab"
require "./src/collectd"
require "./src/logging"
require "./src/util"

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
  def initialize identifier, arguments, statements=[]
    @identifier = identifier
    @arguments = arguments
    @statements = statements
  end

  def [] key, argument=nil
    key = key.to_s.camelize
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
  include Logging

  VALID_OPTIONS = [:flush_socket, :collectd_middleware, :collectd_middleware_name, :plugin_config_dir]

  def self.load file=(ENV["COLLECTD_CONFIG"] || "/etc/collectd.conf")
    @@parser = CollectdConfigParser.new
    @@statements = @@parser.scan_file file
    verify_options
  end

  def self.verify_options
    camels = VALID_OPTIONS.map(&:to_s).map(&:camelize)
    return unless  self[:collect_rack] && self[:collect_rack].statements
    for stmt in self[:collect_rack]&.statements
      @@logger.warn "Unknown CollectRack option '#{stmt.identifier}'" unless camels.include? stmt.identifier
    end
  end

  #find a statement using the identifier and optional first argument
  def self.[] key, argument=nil
    key = key.to_s.camelize
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
    self[:plugin, :unixsock]&.[](:socket_file)&.arguments&.first
  end

  def self.base_dir
    self[:base_dir]&.arguments&.first || "/var/lib/collectd"
  end

  def self.plugin_config_dir
    self[:collect_rack]&.[](:plugin_config_dir)&.arguments&.first || "./plugins"
  end

  def self.interval
    self[:interval]&.arguments&.first&.to_i || 10
  end

  def self.flush_socket
    flush_socket = self[:collect_rack]&.[](:flush_socket)&.arguments&.first
    flush_socket.nil? ? true : flush_socket
  end

  def self.collectd_middleware
    collectd_middleware = self[:collect_rack]&.[](:collectd_middleware)&.arguments&.first
    collectd_middleware.nil? ? false : collectd_middleware
  end

  def self.collectd_middleware_name
    self[:collect_rack]&.[](:collectd_middleware_name)&.arguments&.first || "collectrack"
  end

end
