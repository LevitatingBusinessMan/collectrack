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
    for graph in @plugin.yaml || default_plugin_conf
      puts self.files
      args = [
        "/dev/fd/#{w.fileno}",
        "--start=end-1h",
        "--end=now",
        "--title=#{eval "\"#{graph[:title]}\""} on #{@host}",
        "DEF:a=#{File.join(path, files.first)}:value:AVERAGE",
        "LINE:a#FF0000:value",
        "--width=400"
      ]
      args << "--vertical-label=#{graph[:vertical_label]}" if graph[:vertical_label]
      $log.debug args
      RRD.graph(*args)
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

class Host
  def load
    if self["load"]&.[]("load")
      instance = self["load"]["load"]
      rrd = File.join(instance.path, instance.files.first)
      info = RRD.info(rrd)
      [info["ds[shortterm].last_ds"]&.to_f, info["ds[midterm].last_ds"]&.to_f, info["ds[longterm].last_ds"]&.to_f]
    end
  end
end
