require "collectd"
require "rack"

class Rack::Collectd
  def initialize(app, instance=:default, interval=10, addr="ff18::efc0:4a42", port=25826)
    @app = app
    Collectd.add_server(interval, addr, port)
    @stats = Collectd.rack(instance)
    @cmdline = IO.read("/proc/self/cmdline").split("\x00").first
    # https://github.com/puma/puma/blob/ca201ef69757f8830b636251b0af7a51270eb68a/lib/puma/cluster/worker.rb#L31-L33
    @worker = @cmdline.match(/puma: cluster worker (\d+): \d+.*$/)&.[](1)&.to_i
    init_polls
  end

  def call(env)
    env['cmdline'] = @cmdline
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

  def process_status key
    IO.readlines("/proc/self/status").each do
      it =~ /\:\t/
      return $' if $` == key
    end
  end

  def init_polls
    worker = @worker ? "-#{@worker}" : ""
    @stats.memory("VmRSS#{worker}").polled_gauge do
      process_status('VmRSS')&.to_i&.* 1024
    end
    @stats.memory("VmSize#{worker}").polled_gauge do
      process_status('VmSize')&.to_i&.* 1024
    end
    @stats.cpu("user#{worker}").polled_gauge do
      (Process::times.utime * 100).to_i
    end
    @stats.cpu("system#{worker}").polled_gauge do
      (Process::times.stime * 100).to_i
    end
  end
end
