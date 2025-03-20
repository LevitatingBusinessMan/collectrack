class Host
  attr_reader :name

  def initialize host
    @name = host
  end

  def plugins
    @plugins ||= Plugin.read_plugins self
  end

  def exist?
    File.exist? File.join(Config.base_dir, @name)
  end

  def path
    File.join(Config.base_dir, @name)
  end

  def link
    "/#{@name}"
  end

  def to_s
    @name
  end

  def [] key
    plugins.find { it.to_s == key }
  end

  def has_key? key
    plugins.any? { it.to_s == key }
  end
  alias_method :has_plugin?, :has_key?
end

class Plugin
  attr_reader :name, :instances, :host

  def self.read_plugins host
    plugins = {}
    Dir["*", base: host.path].each do |plugindir|
      name, instance = Plugin.split_dirname plugindir
      plugins[name] ||= []
      plugins[name] << instance
    end

    plugins.map do |p, i|
      Plugin.new host, p, i
    end
  end

  # given a name like disk-dma-0 returns ["disk", "dma-0"]
  def self.split_dirname dirname
    /^(?<name>\w+)(?:-(?<variant>[\w-]+))?$/.match(dirname).captures
  end

  def initialize host, name, instances
    @name = name
    @host = host
    @instances = instances.map { Instance.new self, it }
  end

  def to_s
    @name
  end

  def link
    File.join(@host.link, @name)
  end

  def [] key
    instances.find { it.to_s == key }
  end

  def has_key? key
    instances.any? { it.to_s == key }
  end
  alias_method :has_instance?, :has_key?

  def yamls
    @yamls || if File.exist? yaml_path
      @yamls = YAML.load_stream(File.read(yaml_path), filename: yaml_path, symbolize_names: true).map(&:freeze)
    end
  end

  def yaml_path
    File.join(Config.plugin_config_dir, "#{self}.yaml")
  end

end

class Instance
  attr_reader :name, :plugin, :host

  def initialize plugin, instance_name
    @name = instance_name
    @host = plugin.host
    @plugin = plugin
    @instance = self
  end

  def files
    @files || (@files = Dir["*.rrd", base: path].map { RRDFile.new it, self })
  end

  def dir
    @plugin.name + ("-#{@name}" if @name).to_s
  end
  alias_method :to_s, :dir

  def link
    File.join(@plugin.link, dir)
  end

  def path
    File.join(@host.path, dir)
  end

  def [] key
    files.find { it.to_s == key || it.chomp == key }
  end

  def has_key? key
    files.any? { it.to_s == key || it.chomp == key }
  end
  alias_method :has_file?, :has_key?

end

class RRDFile
  attr_reader :name, :plugin, :host, :instance

  def initialize name, instance
    @name = name
    @instance = instance
    @host = instance.host
    @plugin = instance.plugin
  end

  def to_s
    @name
  end

  def chomp
    @name.chomp(".rrd")
  end

  def path
    File.join(@instance.path, @name)
  end

  def link
    File.join(@instance.link, @name)
  end

end
