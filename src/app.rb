$: << "./libs"

require "sinatra"
require "slim"
require "slim/include"
require "pp"
require "./src/config"
require "./src/collectd"
require "./src/rack_lint_workaround"
require "./src/rrd"
require "./src/view_helpers"

configure :development do
  require "rack-mini-profiler"
  require "stackprof"
  use Rack::MiniProfiler
  Rack::MiniProfiler.config.enable_advanced_debugging_tools = true
end

Slim::Engine.options[:use_html_safe] = true

Config.init

set :slim, layout: :application

get "/" do
  slim :index
end

get "/:host" do
  @host = Host.new(params[:host])
  pass if !@host.exist?
  slim :host
end

get "/:host/:plugin" do
  @host = Host.new(params[:host])
  pass if !@host.has_plugin? params[:plugin]
  @plugin = @host[params[:plugin]]
  slim :plugin
end

get "/:host/:plugin/:instance" do
  @host = Host.new(params[:host])
  pass if !@host.has_plugin? params[:plugin]
  @plugin = @host[params[:plugin]]
  pass if !@plugin.has_instance? params[:instance]
  @instance = @plugin[params[:instance]]
  slim :instance
end

# get "/:host/:plugin/:instance/graph" do
#   @host = Host.new(params[:host])
#   pass if !@host.has_plugin? params[:plugin]
#   @plugin = @host[params[:plugin]]
#   pass if !@plugin.has_instance? params[:instance]
#   @instance = @plugin[params[:instance]]
#   slim :instance
# end

# get "/:host/:plugin/:instance/:file" do
#   @host = Host.new(params[:host])
#   pass if !@host.has_plugin? params[:plugin]
#   @plugin = @host[params[:plugin]]
#   pass if !@plugin.has_instance? params[:instance]
#   @instance = @plugin[params[:instance]]
#   # pass if the file is missing
#   slim :file
# end

not_found do
  slim "h1 #{request.path} was not found"
end
