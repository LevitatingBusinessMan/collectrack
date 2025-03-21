require "socket"
require "./src/config.rb"
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
    return if !@sock
    args = ["FLUSH"]
    case obj
    when Plugin
    when Instance
      args << "plugin=#{obj.plugin}"
    when RRDFile
      args << "plugin=#{obj.plugin}"
      args << "identifier=\"#{obj.host}/#{obj.instance}/#{obj.chomp}\""
    end
    $log.debug("Sending socket: '#{args.join(" ")}'")
    @sock.puts(args.join(" "))
    $log.debug("Socket response: '#{@sock.gets.chomp}'")
  end
end
