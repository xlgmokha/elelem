# frozen_string_literal: true

require_relative "lib/elelem/version"

Gem::Specification.new do |spec|
  spec.name = "elelem"
  spec.version = Elelem::VERSION
  spec.authors = ["mo khan"]
  spec.email = ["mo@mokhan.ca"]

  spec.summary = "A REPL for Ollama."
  spec.description = "A REPL for Ollama."
  spec.homepage = "https://www.mokhan.ca"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.0"
  spec.required_rubygems_version = ">= 3.3.11"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://gitlab.com/mokhax/elelem"
  spec.metadata["changelog_uri"] = "https://gitlab.com/mokhax/elelem/-/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # gemspec = File.basename(__FILE__)
  # spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
  #   ls.readlines("\x0", chomp: true).reject do |f|
  #     (f == gemspec) || f.start_with?(*%w[bin/ test/ spec/ features/ .git Gemfile])
  #   end
  # end
  spec.files = [
    "CHANGELOG.md",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "exe/elelem",
    "lib/elelem.rb",
    "lib/elelem/agent.rb",
    "lib/elelem/api.rb",
    "lib/elelem/application.rb",
    "lib/elelem/configuration.rb",
    "lib/elelem/conversation.rb",
    "lib/elelem/mcp_client.rb",
    "lib/elelem/states/idle.rb",
    "lib/elelem/states/working.rb",
    "lib/elelem/states/working/error.rb",
    "lib/elelem/states/working/executing.rb",
    "lib/elelem/states/working/state.rb",
    "lib/elelem/states/working/talking.rb",
    "lib/elelem/states/working/thinking.rb",
    "lib/elelem/states/working/waiting.rb",
    "lib/elelem/system_prompt.erb",
    "lib/elelem/tool.rb",
    "lib/elelem/toolbox.rb",
    "lib/elelem/toolbox/exec.rb",
    "lib/elelem/toolbox/file.rb",
    "lib/elelem/toolbox/web.rb",
    "lib/elelem/toolbox/mcp.rb",
    "lib/elelem/toolbox/prompt.rb",
    "lib/elelem/tools.rb",
    "lib/elelem/tui.rb",
    "lib/elelem/version.rb",
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "cli-ui"
  spec.add_dependency "erb"
  spec.add_dependency "json"
  spec.add_dependency "json-schema"
  spec.add_dependency "logger"
  spec.add_dependency "net-http"
  spec.add_dependency "open3"
  spec.add_dependency "reline"
  spec.add_dependency "thor"
  spec.add_dependency "timeout"
  spec.add_dependency "uri"
end
