require "socket"
require "./src/config/config.rb"
require "./src/logging.rb"
require "./src/collectd.rb"

class CollectdSock
  def initialize
    return if !Config.unixsock
    begin
      @sock = UNIXSocket.new Config.unixsock
      $log.info "Socket connection at #{Config.unixsock} established"
    rescue Exception => ex
      $log.warn ex.message
    end
  end
  def flush obj=nil
    return unless @sock
    return unless Config.flush_socket
    args = ["FLUSH", "plugin=rrdtool"]
    case obj
    when Plugin
      args << "plugin=#{obj.plugin}"
    when Instance
      args << "plugin=#{obj.plugin}"
      args += obj.files.map { "identifier=\"#{it.host}/#{it.instance}/#{it.chomp}\"" }
    when RRDFile
      args << "plugin=#{obj.plugin}"
      args << "identifier=\"#{obj.host}/#{obj.instance}/#{obj.chomp}\""
    end
    $log.debug("Sending socket: '#{args.join(" ")}'")
    @sock.puts(args.join(" "))
    $log.debug("Socket response: '#{@sock.gets.chomp}'")
  end
end
