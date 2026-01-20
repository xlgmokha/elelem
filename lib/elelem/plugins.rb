# frozen_string_literal: true

module Elelem
  module Plugins
    LOAD_PATHS = [
      File.expand_path("plugins", __dir__),
      "~/.elelem/plugins",
      ".elelem/plugins"
    ].freeze

    def self.setup!(toolbox)
      LOAD_PATHS.each do |path|
        dir = File.expand_path(path)
        next unless File.directory?(dir)

        Dir["#{dir}/*.rb"].sort.each do |file|
          load(file)
        rescue => e
          warn "elelem: failed to load plugin #{file}: #{e.message}"
        end
      end
      registry.each_value { |plugin| plugin.call(toolbox) }
    end

    def self.register(name, &block)
      (@registry ||= {})[name] = block
    end

    def self.registry
      @registry ||= {}
    end
  end
end
