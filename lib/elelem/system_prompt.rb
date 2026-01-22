# frozen_string_literal: true

module Elelem
  class SystemPrompt
    TEMPLATE_PATH = File.expand_path("templates/system_prompt.erb", __dir__)

    attr_reader :memory

    def initialize(memory: nil)
      @memory = memory
    end

    def render
      ERB.new(template, trim_mode: "-").result(binding)
    end

    private

    def template
      File.read(TEMPLATE_PATH)
    end

    def pwd
      Dir.pwd
    end

    def platform
      RUBY_PLATFORM.split("-").last
    end

    def date
      Date.today
    end

    def git_branch
      return unless File.exist?(".git")

      "branch: #{`git branch --show-current`.strip}"
    rescue
      nil
    end

    def repo_map
      `ctags -x --sort=no --languages=Ruby,Python,JavaScript,TypeScript,Go,Rust -R . 2>/dev/null`
        .lines
        .reject { |l| l.include?("vendor/") || l.include?("node_modules/") || l.include?("spec/") }
        .first(100)
        .join
    rescue
      ""
    end

    def agents_md
      Pathname.pwd.ascend.each do |dir|
        file = dir / "AGENTS.md"
        return file.read if file.exist?
      end
      nil
    end
  end
end
