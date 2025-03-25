require "collectd"
require "rack"

class Rack::Collectd
  def initialize(app, instance=:default, interval=10, addr="ff18::efc0:4a42", port=25826)
    @app = app
    Collectd.add_server(interval, addr, port)
    @stats = Collectd.rack(instance)
    @stats.with_full_proc_stats
  end
  def call(env)
    @app.call(env)
  end
end
