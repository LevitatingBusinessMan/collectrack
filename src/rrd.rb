require "RRD"
require "yaml"
require "base64"
require "./src/collectd"
require "./src/config"
require "./src/logging"

module RRD
  # READ_PIPE, WRITE_PIPE = IO.pipe
  # READ_PIPE.binmode
  # WRITE_PIPE.binmode
end

class Instance
  # return one or more graphs ase base64
  def graph
    r, w = IO.pipe
    out = []
    # raise "Graphing #{@plugin} is not yet supported" if not @plugin.yaml
    for graph in @plugin.yaml || self.default_plugin_conf
      args = [
        "/dev/fd/#{w.fileno}",
        "--start=end-1h",
        "--end=now",
        "--title=#{eval "\"#{graph[:title]}\""} on #{@host}",
        "DEF:a=#{File.join(path, files.first)}:value:AVERAGE",
        "LINE:a#FF0000:value",
        "--width=400"
      ]
      $log.debug args
      RRD.graph *args
      out << Base64.encode64(r.read_nonblock(32768))  
    end
    r.close
    w.close
    out
  end

  # like the yaml config but a default
  def default_plugin_conf
    # per default, we attempt to make a single graph plotting the DS name 'value'
    [ 
      {
        title: self
      }
    ]
  end
end
