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
  spec.required_ruby_version = ">= 3.4.0"
  spec.required_rubygems_version = ">= 3.3.11"
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
    "lib/elelem.rb",
    "lib/elelem/agent.rb",
    "lib/elelem/application.rb",
    "lib/elelem/conversation.rb",
    "lib/elelem/system_prompt.erb",
    "lib/elelem/terminal.rb",
    "lib/elelem/tool.rb",
    "lib/elelem/toolbox.rb",
    "lib/elelem/version.rb",
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "cgi", "~> 0.1"
  spec.add_dependency "cli-ui", "~> 2.0"
  spec.add_dependency "erb", "~> 6.0"
  spec.add_dependency "fileutils", "~> 1.0"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "json-schema", "~> 6.0"
  spec.add_dependency "logger", "~> 1.0"
  spec.add_dependency "net-hippie", "~> 1.0"
  spec.add_dependency "net-llm", "~> 0.5", ">= 0.5.0"
  spec.add_dependency "open3", "~> 0.1"
  spec.add_dependency "pathname", "~> 0.1"
  spec.add_dependency "reline", "~> 0.6"
  spec.add_dependency "set", "~> 1.0"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "timeout", "~> 0.1"
end
