# frozen_string_literal: true

module Elelem
  class SystemPrompt
    TEMPLATE_PATH = File.expand_path("templates/system_prompt.erb", __dir__)

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

    def elelem_source
      File.expand_path("../..", __dir__)
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
    rescue Errno::ENOENT
      nil
    end

    def repo_map
      symbols = extract_with_sg
      return ctags_fallback if symbols.nil?

      format_symbols(symbols, budget: 2000)
    end

    def extract_with_sg
      output = `sg run -p 'def $NAME' -l ruby --json=compact . 2>/dev/null`
      return nil unless $?.success?

      JSON.parse(output).map do |match|
        {
          file: match["file"],
          name: match.dig("metaVariables", "single", "NAME", "text")
        }
      end.reject { |m| m[:file].include?("spec/") || m[:file].include?("vendor/") }
    rescue Errno::ENOENT, JSON::ParserError
      nil
    end

    def format_symbols(symbols, budget:)
      result = String.new
      symbols.group_by { |s| s[:file] }.each do |file, syms|
        line = "#{file}: #{syms.map { |s| s[:name] }.uniq.join(", ")}\n"
        break if result.length + line.length > budget
        result << line
      end
      result
    end

    def ctags_fallback
      symbols = `ctags -x --sort=no --languages=Ruby --kinds-Ruby=cfS --exclude=spec --exclude=vendor -R . 2>/dev/null`.lines
        .map { |l| parts = l.split(/\s+/, 4); {file: parts[3]&.split&.first, name: parts[0]} }

      format_symbols(symbols, budget: 2000)
    rescue Errno::ENOENT
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
