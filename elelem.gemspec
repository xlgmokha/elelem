# frozen_string_literal: true

require_relative "lib/elelem/version"

Gem::Specification.new do |spec|
  spec.name = "elelem"
  spec.version = Elelem::VERSION
  spec.authors = ["mo khan"]
  spec.email = ["mo@mokhan.ca"]

  spec.summary = "A minimal coding agent for LLMs."
  spec.description = "A minimal coding agent supporting Ollama, Anthropic, OpenAI, and VertexAI."
  spec.homepage = "https://src.mokhan.ca/xlgmokha/elelem"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.required_rubygems_version = ">= 4.0.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://src.mokhan.ca/xlgmokha/elelem"
  spec.metadata["changelog_uri"] = "https://src.mokhan.ca/xlgmokha/elelem/blob/main/CHANGELOG.md.html"

  spec.files = [
    "CHANGELOG.md",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "exe/elelem",
    "exe/elelem-anthropic",
    "exe/elelem-files",
    "exe/elelem-ollama",
    "exe/elelem-openai",
    "exe/elelem-vertex-ai",
    "lib/elelem.rb",
    "lib/elelem/agent.rb",
    "lib/elelem/terminal.rb",
    "lib/elelem/toolbox.rb",
    "lib/elelem/version.rb",
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "date", "~> 3.0"
  spec.add_dependency "fileutils", "~> 1.0"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "net-hippie", "~> 1.0"
  spec.add_dependency "open3", "~> 0.1"
  spec.add_dependency "pathname", "~> 0.1"
  spec.add_dependency "reline", "~> 0.6"
  spec.add_dependency "stringio", "~> 3.0"
  spec.add_dependency "tempfile", "~> 0.3"
  spec.add_dependency "uri", "~> 1.0"
end
