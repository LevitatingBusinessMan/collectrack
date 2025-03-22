require "standard/rake"
require 'rspec/core/rake_task'

task default: %w[lexer parser spec]

RSpec::Core::RakeTask.new(:spec)

desc "Generate collectd.conf lexer"
task :lexer do
  `bin/rex src/config/config.rex`
end

desc "Generate collectd.conf parser"
task :parser do
  `bin/racc src/config/config.racc`
end
