# frozen_string_literal: true

module Elelem
  module Plugins
    LOAD_PATHS = [".elelem/plugins", "~/.elelem/plugins"].freeze

    def self.load!
      LOAD_PATHS.each do |path|
        dir = File.expand_path(path)
        next unless File.directory?(dir)

        Dir["#{dir}/*.rb"].sort.each do |file|
          load(file)
        rescue => e
          warn "elelem: failed to load plugin #{file}: #{e.message}"
        end
      end
    end

    def self.register(name, &block)
      (@registry ||= {})[name] = block
    end

    def self.registry
      @registry ||= {}
    end
  end
end
