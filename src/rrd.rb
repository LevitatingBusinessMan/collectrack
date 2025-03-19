require "RRD"
require "yaml"
require "base64"
require "./src/collectd"
require "./src/config"
require "./src/logging"
require "./src/util"

class Colors
  Crimson = "#DC143C"
  Coral = "#FF7F50"
  LightSeaGreen = "#20B2AA"
  MediumOrchid = "#BA55D3"
  CornFlowerBlue = "#6495ED"
  DarkSeaGreen = "#8FBC8F"
  OliveDrab = "#6B8E23"
  LightPink = "#FFB6C1"

  DEFAULTS = [
    Colors::Crimson,  Colors::LightSeaGreen,
    Colors::MediumOrchid, Colors::CornFlowerBlue, Colors::DarkSeaGreen,
    Colors::LightPink, Colors::Coral
  ].freeze

  def initialize
    @queue = DEFAULTS.dup
  end

  def next_color
    @queue = DEFAULTS.dup if @queue.empty?
    @queue.shift
  end
end

module RRD
  # READ_PIPE, WRITE_PIPE = IO.pipe
  # READ_PIPE.binmode
  # WRITE_PIPE.binmode
end

class Instance
  # return one or more graphs as base64
  def graph options={}
    r, w = IO.pipe
    out = []

    for graph in @plugin.yaml || default_plugin_conf
      begin
        args = [
          "/dev/fd/#{w.fileno}",
          "--start=end-1h",
          "--end=now",
          "--title=#{evalstr graph[:title]} on #{@host}",
          "--width=#{options[:width] || 500}",
          "--height=#{options[:height] || 150}"
        ]
        args << "--vertical-label=#{graph[:vertical_label]}" if graph[:vertical_label]

        colors = Colors.new

        lineno = 0
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
          legend = line[:legend] || line[:ds] || filename.delete_prefix("#{@plugin}-").delete_suffix(".rrd")
          color = line[:color] || colors.next_color
          cf = line[:cf] || "AVERAGE"
          thickness = line[:thickness] || 1

          vname_in = "#{ds}#{lineno}"
          vname_out = if line[:inverted] then "#{vname_in}_inv" else vname_in end

          args << "DEF:#{vname_in}=#{file}:#{ds}:#{cf}"
          args << "CDEF:#{vname_out}=#{vname_in},-1,*" if line[:inverted]
          args << "LINE#{thickness}:#{vname_out}#{color}:#{legend}"
          lineno += 1
        end
      args += graph[:opts] if graph[:opts]

      $log.debug args
      RRD.graph(*args)
      out << Base64.encode64(r.read_nonblock(262144))
      rescue Exception => ex
        $log.warn ex.message
        raise ex
        next
      end
    end
    r.close
    w.close
    out
  end

  # like the yaml config but a default
  def default_plugin_conf
    # per default, we attempt to make a single graph plotting the DS name 'value' from each file
    self.files.map { |file| {
      title: "#{file.chomp(".rrd")} (#{self})",
      lines: get_dss(file).map { |ds| {
        ds: ds,
        file: file.chomp(".rrd")
      } }
    } }
  end

  def get_dss filename
    info = RRD.info File.join(path, filename)
    info.keys.map { /^ds\[(\w+)\]/.match(it)&.[] 1 }.select(&:itself).uniq
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
