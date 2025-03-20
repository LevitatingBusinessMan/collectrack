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
  # class RRD.yaml
  # end
end

module Graphable
  # may return nil
  def graph_yaml yaml, options={}
    r, w = IO.pipe
    
    if yaml[:file]&.match?(/^\/.+\/$/)
      yaml = @instance.update_regex_filename_yaml yaml
      return if not yaml[:lines] or yaml[:lines].empty?
    end

    $log.debug yaml

    args = [
      "/dev/fd/#{w.fileno}",
      "--start=end-1h",
      "--end=now",
      "--title=#{evalstr yaml[:title]} on #{@host}",
      "--width=#{options[:width] || 500}",
      "--height=#{options[:height] || 150}"
    ]
    args << "--vertical-label=#{yaml[:vertical_label]}" if yaml[:vertical_label]

    colors = Colors.new

    lines = yaml[:lines] || (@instance[yaml[:file]]&.default_lines if yaml[:file]) || @instance.default_file&.default_lines

    if !lines
      raise "Cannot find adequate file to draw value from"
    end

    $log.debug lines if not yaml[:lines]

    lineno = 0
    for line in lines
      # if the line has no file, attempt a globally configured file, otherwise use a file with the name of the plugin, otherwise use the only file, otherwise error
      filename = line[:file]&.+(".rrd") || yaml[:file]&.+(".rrd") || @instance.default_file.to_s

      if not filename
        raise "Cannot find adequate file to draw value from"
      end

      file = File.join(@instance.path, filename)

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
    args += yaml[:opts] if yaml[:opts]

    $log.debug args
    begin
      RRD.graph(*args)
    rescue Exception => ex
      $log.warn ex.message
      raise ex
    end
    out = r.read_nonblock(262144)
    r.close
    w.close
    out
  end
end

class Instance
  include Graphable

  def graph n, options={}
    graph_yaml(@plugin.yamls&.[] n || self.files[n].default_yaml)
  end

  def graph_count
    @plugin.yamls&.length || self.files.length
  end

  # return one or more graphs as base64
  def graphs options={}
    effective_yamls.map {
      graph_yaml it, options
    }.compact 
  end

  # WARNING a default yamls requires reading RRD.info for each file
  def effective_yamls
    @plugin.yamls || default_yamls
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

  def info
    RRD.info path
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
    Base64.encode64 graph_yaml(default_yaml, options)
  end

end

