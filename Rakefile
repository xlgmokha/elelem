# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :files do
  IO.popen(%w[git ls-files], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines.each do |f|
      next if f.start_with?(*%w[bin/ spec/ pkg/ .git .rspec Gemfile Rakefile])
      next if f.strip.end_with?(*%w[.toml .txt .md])

      puts f
    end
  end
end

task default: %i[spec]
