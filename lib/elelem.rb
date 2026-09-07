# frozen_string_literal: true

require "erb"
require "forwardable"
require "json"
require "json_schemer"
require "logger"
require "open3"
require "pathname"
require "shellwords"

require_relative "elelem/agent"
require_relative "elelem/slash_command"
require_relative "elelem/commands"
require_relative "elelem/conversation"
require_relative "elelem/input"
require_relative "elelem/null_input"
require_relative "elelem/output"
require_relative "elelem/null_output"
require_relative "elelem/plugins"
require_relative "elelem/registration"
require_relative "elelem/registry"
require_relative "elelem/config"
require_relative "elelem/result"
require_relative "elelem/stub_provider"
require_relative "elelem/system_prompt"
require_relative "elelem/tool"
require_relative "elelem/null_tool"
require_relative "elelem/toolbox"
require_relative "elelem/version"

module Elelem
  def self.start(provider: "stub", toolbox: Toolbox.new)
    self.build(provider: provider, toolbox: toolbox).repl
  end

  def self.ask(prompt, provider: "stub", toolbox: Toolbox.new, output: NullOutput.new)
    self.build(provider: provider, toolbox: toolbox, input: NullInput.new, output: output).turn(prompt)
  end

  def self.build(provider: "stub", toolbox: Toolbox.new, input: nil, output: nil)
    Config.build_agent(provider, toolbox: toolbox, input: input, output: output)
  end

  def self.logger
    @logger ||= Logger.new($stderr).tap do |log|
      log.level = Logger.const_get(ENV.fetch("ELELEM_LOG_LEVEL", "warn").upcase)
    end
  end
end

Elelem.configure { |config| config.provider(:stub) { Elelem::StubProvider.new } }
