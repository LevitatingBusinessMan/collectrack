require "socket"
require "./src/config/config.rb"
require "./src/logging.rb"
require "./src/collectd.rb"

class CollectdSock
  include Logging

  def initialize
    return if !Config.unixsock
    begin
      @sock = UNIXSocket.new Config.unixsock
      @sock.timeout = 1
      @mutex = Thread::Mutex.new
      logger.info "Socket connection at #{Config.unixsock} established"
    rescue Exception => ex
      logger.warn ex.message
    end
  end
  def flush obj=nil
    return unless @sock
    return unless Config.flush_socket
    args = ["FLUSH", "plugin=rrdtool", "plugin=network"]
    case obj
    when Plugin
      args << "plugin=#{obj.plugin}"
    when PluginInstance
      args << "plugin=#{obj.plugin}"
      args += obj.files.map { "identifier=\"#{it.host}/#{it.instance.dir}/#{it.chomp}\"" }
    when RRDFile
      args << "plugin=#{obj.plugin}"
      args << "identifier=\"#{obj.host}/#{obj.instance}/#{obj.chomp}\""
    end
    logger.debug("Sending socket: '#{args.join(" ")}'")
    begin
      @mutex.synchronize {
        @sock.puts(args.join(" "))
        logger.debug("Socket response: '#{@sock.gets.chomp}'")
      }
    rescue Exception => ex
      logger.error ex.detailed_message
    end
  end
end
