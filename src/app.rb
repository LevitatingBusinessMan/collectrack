# $:.unshift "./libs"

require "sinatra"
require "slim"
require "slim/include"
require "pp"
require "rack/common_logger"
require "./src/collectd"
require "./src/rrd"
require "./src/view_helpers"
require "./src/unixsock"
require "./src/config/config"
require "./src/version"
require "./src/logging"

# because tilt shadows the VERSION global
COLLECTRACK_VERSION = VERSION

Config.load

configure :development do
  ENV['APP_ENV'] = "development"
  require "rack-mini-profiler"
  require "stackprof"
  use Rack::MiniProfiler
  Rack::MiniProfiler.config.enable_advanced_debugging_tools = true
  Rack::MiniProfiler.config.flamegraph_ignore_gc = true
  Rack::MiniProfiler.config.flamegraph_sample_rate = 0.1
  use Rack::Lint
  use Rack::CommonLogger, Logging.logger
end

if Config.collectd_middleware
  require "./src/collectd_middleware"
  Logging.logger.info "Using Rack::Collectd middleware"
  use(Rack::Collectd, Config.collectd_middleware_name)
end

disable :logging

Slim::Engine.options[:use_html_safe] = true

set unixsock: CollectdSock.new

set :slim, layout: :application

before do
  @query = request.env["rack.request.query_hash"].symbolize_keys
  @query.select! {|_, value| if value.respond_to?(:empty?) then !value.empty? else true end }
  @query_string = request.env["rack.request.query_string"]
  @uri = URI(request.env["REQUEST_URI"]).freeze
  env['rack.logger'] = Logging.logger
  headers "x-collectrack-version" => VERSION
end

get "/" do
  settings.unixsock.flush
  slim :index
end

get "/:host" do
  @host = Host.new(params[:host])
  pass if !@host.exist?
  settings.unixsock.flush @instance

  slim :host
end

get "/:host/:plugin" do
  @host = Host.new(params[:host])
  pass if !@host.has_plugin? params[:plugin]
  @plugin = @host[params[:plugin]]
  settings.unixsock.flush @instance

  slim :plugin
end

get "/:host/:plugin/:instance" do
  @host = Host.new(params[:host])
  pass if !@host.has_plugin? params[:plugin]
  @plugin = @host[params[:plugin]]
  pass if !@plugin.has_instance? params[:instance]
  @instance = @plugin[params[:instance]]
  settings.unixsock.flush @instance

  slim :instance
end

get "/:host/:plugin/:instance/graph" do
  @host = Host.new(params[:host])
  pass if !@host.has_plugin? params[:plugin]
  @plugin = @host[params[:plugin]]
  pass if !@plugin.has_instance? params[:instance]
  @instance = @plugin[params[:instance]]
  n = Integer(params[:n]) rescue nil
  pass if !n

  content_type :png
  headers "content-disposition" => "filename=\"#{@instance.graph_title(n)}\""
  expires Config.interval # this doesn't seem to work
  body = @instance.graph(n, @query) || pass
  body
end

get "/:host/:plugin/:instance/:file.rrd" do
  @host = Host.new(params[:host])
  pass if !@host.has_plugin? params[:plugin]
  @plugin = @host[params[:plugin]]
  pass if !@plugin.has_instance? params[:instance]
  @instance = @plugin[params[:instance]]
  pass if !@instance.has_file? params[:file]
  @file = @instance[params[:file]]

  slim :file
end

# get "/:host/:plugin/:instance/:file.rrd/graph" do
#   @host = Host.new(params[:host])
#   pass if !@host.has_plugin? params[:plugin]
#   @plugin = @host[params[:plugin]]
#   pass if !@plugin.has_instance? params[:instance]
#   @instance = @plugin[params[:instance]]
#   pass if !@instance.has_file? params[:file]
#   @file = @instance[params[:file]]

#   content_type :png
#   headers "content-disposition" => "filename=\"#{@file.graph_title}\""
#   body = @file.graph(@query) || pass
#   body
# end

not_found do
  slim "h1= \"#{request.fullpath} was not found\""
end

get "/favicon.ico" do
  content_type :png
  File.open "favicon.ico"
end

get "/icon.png" do
  content_type :png
  File.open "icon.png"
end
