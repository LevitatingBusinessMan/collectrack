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
    start = Time.now
    begin
      status, headers, body = @app.call(env)
    rescue Exception => ex
      @stats.http_requests("5xx").count! 1
      raise ex
    else
      env['rack.logger'].debug "Response time #{(Time.now - start) * 1000}ms"
      @stats.response_time(nil).gauge = Time.now - start
      @stats.http_requests("#{status.to_s[0]}xx").count! 1
      [status, headers, body]
    end
  end
end
