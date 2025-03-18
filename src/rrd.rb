require "RRD"
require "yaml"
require "base64"
require "./src/collectd"
require "./src/config"
require "./src/logging"

module Colors
  CRIMSON = "#DC143C"
end

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

    for graph in @plugin.yaml || default_plugin_conf
      args = [
        "/dev/fd/#{w.fileno}",
        "--start=end-1h",
        "--end=now",
        "--title=#{eval "\"#{graph[:title]}\""} on #{@host}",
        "--width=400"
      ]
      args << "--vertical-label=#{graph[:vertical_label]}" if graph[:vertical_label]

      vname = 0
      for line in graph[:lines]
        filename = line[:file]&.+(".rrd") || ("#{@plugin}.rrd" if files.include? "#{@plugin}.rrd") || (files[0] if files.length == 1)

        if not filename
          raise "Cannot find adequate file to draw value from"
        end

        file = File.join(path, filename)

        if not File.exist? file
          $log.warn "#{file} not found"
          next
        end

        ds = line[:ds] || "value"
        legend = line[:legend] || line[:ds] || filename.chomp(".rrd")
        color = nil
        cf = line[:cf] || "AVERAGE"
        thickness = line[:thickness] || 1

        args += [
          "DEF:#{vname}=#{file}:#{ds}:#{cf}",
          "LINE#{thickness}:#{vname}#{Colors::CRIMSON}:#{legend}",
        ]
        vname += 1
      end

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
    # per default, we attempt to make a single graph plotting the DS name 'value' from each file
    [
      {
        title: self,
        lines: self.files.map { {
          file: it.chomp(".rrd"),
          name: it
        } }
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
