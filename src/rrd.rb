require "RRD"
require "yaml"
require "./src/collectd"
require "./src/config"

class Instance
  def graph
    raise "Graphing #{@plugin} is not yet supported" if !@plugin.yaml
  end
end
