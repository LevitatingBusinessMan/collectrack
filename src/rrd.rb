require 'RRD'
require 'yaml'
require './src/collectd.rb'
require './src/config.rb'

class Instance
  def graph
    raise "Graphing #{@plugin} is not yet supported" if !@plugin.yaml
  end
end
