# frozen_string_literal: true

require "erb"
require "fileutils"
require "json"
require "json-schema"
require "logger"
require "net/llm"
require "open3"
require "pathname"
require "reline"
require "set"
require "thor"
require "timeout"

require_relative "elelem/agent"
require_relative "elelem/application"
require_relative "elelem/conversation"
require_relative "elelem/tool"
require_relative "elelem/tools"
require_relative "elelem/version"

Reline.input = $stdin
Reline.output = $stdout

module Elelem
  class Error < StandardError; end
end
