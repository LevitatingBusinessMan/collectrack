require "standard/rake"
require 'rspec/core/rake_task'

task default: %w[lexer parser spec]

RSpec::Core::RakeTask.new(:spec)

desc "Generate collectd.conf lexer"
task :lexer do
  `bin/rex src/config/scanner.rex`
end

desc "Generate collectd.conf parser"
task :parser do
  `bin/racc src/config/parser.racc`
end

desc "Generate vendor tarball"
task :vendor do
  `bundle cache`
  `tar cf vendor.tar.xz vendor`
  FileUtils.rm_r "vendor"
end

desc "Commit src/version.rb and set git tag"
task :release, [:version] do |t, args|
  File.write(p("src/version.rb"), p( <<-EOF
# generated with rake release[#{args[:version]}]
VERSION = \"#{args[:version]}\"
EOF
  ))
  `git add src/version.rb`
  `git commit -m "src/version.rb #{args[:version]}" --no-edit`
  `git tag #{args[:version]}`
end
