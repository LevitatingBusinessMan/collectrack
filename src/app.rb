$: << './libs'

require 'sinatra'
require 'slim'
require 'slim/include'
require './src/config'
require './src/collectd'
require './src/rack_lint_workaround'
require './src/rrd'
require './src/view_helpers'


require 'rack-mini-profiler' if settings.development? 
require 'stackprof' if settings.development? 
use Rack::MiniProfiler if settings.development? 

Slim::Engine.options[:use_html_safe] = true

Config.init

set :slim, layout: :application

get '/' do
  slim :index
end

get '/:host'do
  @host = Host.new(params[:host])
  pass if not @host.exist?
  slim :host
end

get '/:host/:plugin'do
  @host = Host.new(params[:host])
  pass if not @host.has_plugin? params[:plugin]
  @plugin = @host[params[:plugin]]
  slim :plugin
end

get '/:host/:plugin/:instance'do
  @host = Host.new(params[:host])
  pass if not @host.has_plugin? params[:plugin]
  @plugin = @host[params[:plugin]]
  pass if not @plugin.has_instance? params[:instance]
  @instance = @plugin[params[:instance]]
  slim :instance
end

not_found do
  slim 'h1 #{request.path} was not found'
end
