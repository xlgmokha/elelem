# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
# require "rb_sys/extensiontask"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

# task build: :compile

# RbSys::ExtensionTask.new("elelem", Gem::Specification.load("elelem.gemspec")) do |ext|
#   ext.lib_dir = "lib/elelem"
# end

# task default: %i[compile spec rubocop]
task default: %i[spec rubocop]
