# frozen_string_literal: true

require "json"
require "logger"
require "net/http"
require "open3"
require "thor"
require "uri"

require_relative "elelem/agent"
require_relative "elelem/api"
require_relative "elelem/application"
require_relative "elelem/configuration"
require_relative "elelem/conversation"
require_relative "elelem/tools"
require_relative "elelem/version"

module Elelem
  class Error < StandardError; end
end
