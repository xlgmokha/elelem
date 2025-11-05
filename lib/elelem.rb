# frozen_string_literal: true

require "cli/ui"
require "erb"
require "json"
require "json-schema"
require "logger"
require "net/llm"
require "open3"
require "reline"
require "thor"
require "timeout"

require_relative "elelem/agent"
require_relative "elelem/api"
require_relative "elelem/application"
require_relative "elelem/configuration"
require_relative "elelem/conversation"
require_relative "elelem/mcp_client"
require_relative "elelem/tool"
require_relative "elelem/toolbox"
require_relative "elelem/tools"
require_relative "elelem/tui"
require_relative "elelem/version"

CLI::UI::StdoutRouter.enable
Reline.input = $stdin
Reline.output = $stdout

module Elelem
  class Error < StandardError; end
end
