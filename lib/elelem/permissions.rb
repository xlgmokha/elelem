# frozen_string_literal: true

module Elelem
  class Permissions
    LOAD_PATHS = [
      File.expand_path("permissions.json", __dir__),
      "~/.elelem/permissions.json",
      ".elelem/permissions.json"
    ].freeze

    def initialize
      @rules = LOAD_PATHS.reduce({}) do |rules, path|
        rules.merge(load_config(File.expand_path(path)))
      end
    end

    def check(tool_name, args, terminal:)
      policy = @rules[tool_name.to_sym] || :ask
      case policy
      when :allow then true
      when :deny then raise "Permission denied: #{tool_name}"
      when :ask then prompt(tool_name, args, terminal)
      end
    end

    private

    def load_config(path)
      return {} unless File.exist?(path)

      JSON.parse(File.read(path)).transform_keys(&:to_sym).transform_values(&:to_sym)
    rescue JSON::ParserError
      {}
    end

    def prompt(tool_name, args, terminal)
      return true unless $stdin.tty?

      answer = terminal.ask("  Allow? [Y/n] > ")&.downcase
      raise "User denied permission: #{tool_name}" if answer == "n"

      true
    end
  end
end
