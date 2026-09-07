# frozen_string_literal: true

module Elelem
  class Plugins
    LOAD_PATHS = [
      "~/.agents/plugins",
      ".agents/plugins"
    ].freeze

    def initialize(load_paths: LOAD_PATHS)
      @loaded = false
      @load_paths = load_paths
    end

    def load!(force: false)
      return if @loaded && !force

      @load_paths.each do |path|
        dir = File.expand_path(path)
        next unless File.directory?(dir)

        Dir["#{dir}/*.rb"].sort.each do |file|
          load(file)
        rescue => e
          warn "elelem: failed to load plugin #{file}: #{e.message}"
        end
      end

      @loaded = true
    end
  end
end
