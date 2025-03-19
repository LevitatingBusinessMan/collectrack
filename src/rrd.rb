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
  def graph_yaml yaml, options={}
    r, w = IO.pipe

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

  # return one or more graphs as base64
  def graph options={}
    out = []

    for yaml in @plugin.yaml || default_yaml
      if yaml[:file]&.match? /^\/.+\/$/
        files.map { it.yaml_regex_filename yaml }.compact.each {
          out << Base64.encode64(graph_yaml(it, options))
        }
      else
        out << Base64.encode64(graph_yaml(yaml, options))
      end
    end
  
    out
  end

  # like the yaml config but a default
  def default_yaml
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

  # update a yaml that has a regex filename
  def yaml_regex_filename yaml
    if caps = Regexp::new(yaml[:file].delete_prefix('/').delete_suffix('/')).match(chomp)&.named_captures
      nyaml = yaml.dup
      nyaml[:file] = chomp
      if caps["legend"]
        if not nyaml[:lines]
          nyaml[:lines] = [{legend: caps["legend"]}]
        elsif nyaml[:lines].length == 1
          nyaml[:lines][0][legend: caps["legend"]]
        end
      end
      nyaml
    end
  end

end

