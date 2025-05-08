require "RRD"
require "yaml"
require "base64"
require 'fcntl'
require "./src/collectd"
require "./src/config/config"
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

module Graphable
  include Logging

  DEFAULT_GRAPH_WIDTH = 600
  DEFAULT_GRAPH_HEIGHT = 200

  # may return nil
  def graph_yaml yaml, options={}
    r, w = IO.pipe autoclose: true, binmode: true
    r.singleton_class.undef_method(:to_path) # unnecessary in puma master
    max_pipe_size = File.read("/proc/sys/fs/pipe-max-size").to_i
    r.fcntl(Fcntl::F_SETPIPE_SZ, max_pipe_size)

    if yaml[:file]&.match?(/^\/.+\/$/)
      yaml = @instance.update_regex_filename_yaml yaml
      return if not yaml[:lines] or yaml[:lines].empty?
    end

    logger.debug yaml
    logger.debug options

    span = options[:span] || "6h"
    span = "1#{span}" if not span[0].numeric?

    args = [
      "/dev/fd/#{w.fileno}",
      "--start=end-#{span}",
      "--end=now",
      "--title=#{evalstr yaml[:title]} on #{@host}",
      "--width=#{options[:width] || DEFAULT_GRAPH_WIDTH}",
      "--height=#{options[:height] || DEFAULT_GRAPH_HEIGHT}",
      "--full-size-mode"
    ]
    args << "--vertical-label=#{yaml[:vertical_label]}" if yaml[:vertical_label]

    colors = Colors.new

    lines = yaml[:lines] || (@instance[yaml[:file]]&.default_lines if yaml[:file]) || @instance.default_file&.default_lines

    if !lines
      raise "Cannot find adequate file to draw value from"
    end

    logger.debug lines if not yaml[:lines]

    lineno = 0
    for line in lines
      # if the line has no file, attempt a globally configured file, otherwise use a file with the name of the plugin, otherwise use the only file, otherwise error
      filename = line[:file]&.+(".rrd") || yaml[:file]&.+(".rrd") || @instance.default_file.to_s

      if not filename
        raise "Cannot find adequate file to draw value from"
      end

      file = File.join(@instance.path, filename)

      if not File.exist? file
        logger.debug "#{file} not found"
        next
      end

      ds = line[:ds] || "value"
      legend = line[:legend] || line[:ds] || filename.delete_prefix("#{@plugin}-").delete_suffix(".rrd")
      color = line[:color] || colors.next_color
      cf = line[:cf] || "AVERAGE"
      thickness = line[:thickness] || 1
      statement = yaml[:area] ? "AREA" : "LINE#{line[:thickness]}"
      stack = ":STACK" if yaml[:stacked]
      skipscale = ":skipscale" if line[:skipscale]

      vname_in = "#{ds}#{lineno}"
      vname_out = if line[:inverted] then "#{vname_in}_inv" else vname_in end

      args << "DEF:#{vname_in}=#{file}:#{ds}:#{cf}"
      args << "CDEF:#{vname_out}=#{vname_in},-1,*" if line[:inverted]
      args << "#{statement}:#{vname_out}#{color}:#{legend}#{stack}#{skipscale}"
      lineno += 1
    end
    args += yaml[:opts] if yaml[:opts]

    return if lineno == 0

    logger.debug args
    start = Time.now
    begin
      logger.debug RRD.graphv(*args)
    rescue Exception => ex
      w.close
      r.close
      raise ex
    else
      w.close
      logger.debug "RRD ran for #{(Time.now - start) * 1000}ms"
      return r
    end
  end
end

class PluginInstance
  include Graphable

  def graph n, options={}
    graph_yaml((effective_yaml(n) || return nil), options)
  end

  def graph_title n
    "#{evalstr effective_yaml(n)&.[] :title} on #{@host}"
  end

  def graph_count
    @plugin.yamls&.length || self.files.length
  end

  # return one or more graphs as base64
  def graphs options={}
    effective_yamls.map {
      graph_yaml(it, options)
    }.compact 
  end

  # WARNING a default yamls requires reading RRD.info for each file
  def effective_yamls
    @plugin.yamls || default_yamls
  end

  def effective_yaml n
    @plugin.yamls&.[](n) || self.files[n]&.default_yaml
  end

  # add lines to a yaml where the filename is a regex
  def update_regex_filename_yaml yaml
    regex = Regexp.new(yaml[:file]&.match(/^\/(.+)\/$/)&.[] 1)
    nyaml = yaml.dup
    nyaml.delete :file
    og_lines = nyaml[:lines].dup || [{}]
    nyaml[:lines] = []
    for file in files
      if caps = regex.match(file.chomp)&.named_captures
        nyaml[:lines] += og_lines.map {
          it.merge({
            file: file.chomp,
            legend: caps["legend"]
          }.compact) 
        }
      end
    end
    nyaml
  end

  # like the yaml config but a default
  def default_yamls
    # per default, we attempt to make a single graph plotting the DS name 'value' from each file
    self.files.map(&:default_yaml)
  end

  # attempt to find the file matching the plugin name or the only file
  def default_file
    files.find { it.name == "#{@plugin}.rrd"} || (files[0] if files.length == 1)
  end

end

class Host
  def load
    if self["load"]&.[]("load")
      instance = self["load"]["load"]
      info = instance.files.first.info
      return if info["last_update"]& - Time.now.to_i > 5 * 60
      [info["ds[shortterm].last_ds"]&.to_f, info["ds[midterm].last_ds"]&.to_f, info["ds[longterm].last_ds"]&.to_f]
    end
  end
end

class RRDFile
  include Graphable
  include Logging

  def graph options={}
    graph_yaml(default_yaml, options)
  end

  def graph_title
    "#{evalstr default_yaml[:title]} on #{@host}"
  end

  def info
    begin
      RRD.info path
    rescue Exception => ex
      logger.error ex.detailed_message
    end
  end

  def get_dss
    info.keys.map { /^ds\[(\w+)\]/.match(it)&.[] 1 }.select(&:itself).uniq
  end

  def default_yaml
    {
      title: "#{chomp} (#{@instance})",
      file: chomp
    }
  end

  def default_lines
    get_dss.map { {
      ds: it,
      file: chomp
    } }
  end

  def graph options={}
    Base64.encode64 graph_yaml(default_yaml, options).read
  end

end

