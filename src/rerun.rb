require "listen"
COMMAND = ARGV.empty? ? ["rackup -s puma"] : ARGV

listener = Listen.to "./src/", only: /\.rb$/ do
  start
end
listener.start

def start
  if not system "pumactl --control-url unix://#{ENV['XDG_RUNTIME_DIR']}/collectrack_puma.sock restart"
    $pid = Process.spawn(*COMMAND)
    puts "Spawned '#{COMMAND.join ' '}' pid #{$pid}"
  end
end

at_exit do
  puts "stopping"
  `pumactl --control-url unix://#{ENV['XDG_RUNTIME_DIR']}/collectrack_puma.sock stop`
end

start
begin sleep; rescue Interrupt; end
