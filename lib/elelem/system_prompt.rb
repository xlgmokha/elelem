# frozen_string_literal: true

module Elelem
  class SystemPrompt
    DEFAULT = File.read(File.expand_path("prompts/default.erb", __dir__)).freeze

    attr_accessor :template

    def initialize(template = nil)
      @template = template || DEFAULT
    end

    def render
      ERB.new(template, trim_mode: "-").result(binding)
    end

    private

    def agents_md
      Pathname.pwd.ascend.each do |dir|
        file = dir / "AGENTS.md"
        return file.read if file.exist?
      end
      nil
    end
  end
end
