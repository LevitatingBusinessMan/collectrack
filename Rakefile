require "standard/rake"
require 'rspec/core/rake_task'

task default: %w[lexer parser spec]

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = "--format documentation"
end

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
  `bundle cache --all-platforms`
  `tar cJf vendor.tar.xz vendor`
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

desc "Generate a changelog"
task :changelog, [:tag] do |t, args|
  prev = `git describe --abbrev=0 --tags #{args[:tag]}^`.chomp
  STDERR.puts "Identified #{prev} as previous commit"
  puts <<~EOF
  Commits in this release:
  #{`git log --abbrev-commit --decorate --format=format:'* (%h) %s' #{prev}..#{args[:tag]}`}
  EOF
end
