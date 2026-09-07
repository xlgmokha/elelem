# frozen_string_literal: true

require_relative "lib/elelem/version"

Gem::Specification.new do |spec|
  spec.name = "elelem"
  spec.version = Elelem::VERSION
  spec.authors = ["mo khan"]
  spec.email = ["mo@mokhan.ca"]

  spec.summary = "A minimal coding harness for LLMs."
  spec.description = "A minimal coding harness."
  spec.homepage = "https://src.mokhan.ca/xlgmokha/elelem"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.required_rubygems_version = ">= 4.0.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://git.mokhan.ca/xlgmokha/elelem.git"

  spec.files = [
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "exe/elelem",
    "lib/elelem.rb"
  ] + Dir["lib/elelem/*.rb"] + Dir["lib/elelem/prompts/**/*.erb"]
  spec.bindir = "exe"
  spec.executables = ["elelem"]
  spec.require_paths = ["lib"]

  spec.add_dependency "erb", "~> 6.0"
  spec.add_dependency "forwardable", "~> 1.4"
  spec.add_dependency "io-console", "~> 0.9"
  spec.add_dependency "json", "~> 3.0"
  spec.add_dependency "json_schemer", "~> 2.5"
  spec.add_dependency "logger", "~> 1.7"
  spec.add_dependency "open3", "~> 0.2"
  spec.add_dependency "optparse", "~> 0.8"
  spec.add_dependency "pathname", "~> 0.5"
  spec.add_dependency "reline", "~> 0.7"
  spec.add_dependency "shellwords", "~> 0.2"
  spec.add_dependency "uri", "~> 1.0"
end
