# frozen_string_literal: true

module Elelem
  class SystemPrompt
    LOAD_PATHS = [
      File.expand_path("prompts", __dir__),
      File.expand_path("~/.elelem/prompts"),
      ".elelem/prompts"
    ].freeze

    class << self
      def templates
        @templates ||= load_templates
      end

      def available_modes
        templates.keys.sort
      end

      def get(name)
        templates[name.to_s] || templates["default"]
      end

      def reload!
        @templates = nil
      end

      private

      def load_templates
        result = {}
        LOAD_PATHS.each do |dir|
          next unless File.directory?(dir)

          Dir[File.join(dir, "*.erb")].each do |path|
            result[File.basename(path, ".erb")] = File.read(path)
          end
        end
        result
      end
    end

    attr_accessor :template
    attr_reader :mode

    def initialize(template = nil)
      @mode = "default"
      @template = template || self.class.get("default")
    end

    def switch(name)
      @mode = name
      @template = self.class.get(name)
    end

    def render
      ERB.new(template, trim_mode: "-").result(binding)
    end

    private

    def pwd = Dir.pwd
    def platform = RUBY_PLATFORM.split("-").last
    def date = Date.today

    def elelem_source
      spec = Gem.loaded_specs["elelem"]
      spec ? spec.gem_dir : File.expand_path("../..", __dir__)
    end

    def git_info
      return unless File.exist?(".git")
      "branch: #{`git branch --show-current`.strip}"
    rescue Errno::ENOENT
      nil
    end

    def repo_map
      files = `git ls-files '*.rb' 2>/dev/null`.lines.map(&:strip)
      return "" if files.empty?

      symbols = extract_symbols(files)
      format_symbols(symbols, budget: 2000)
    end

    def extract_symbols(files)
      output, status = Open3.capture2("sg", "run", "-p", "def $NAME", "-l", "ruby", "--json=compact", ".", err: File::NULL)
      return ctags_fallback(files) unless status.success?

      parse_sg_output(output, files)
    end

    def parse_sg_output(output, tracked_files)
      JSON.parse(output).filter_map do |match|
        file = match["file"]
        next unless tracked_files.include?(file)
        { file: file, name: match.dig("metaVariables", "single", "NAME", "text") }
      end
    rescue JSON::ParserError
      []
    end

    def ctags_fallback(files)
      return [] if files.empty?

      output = IO.popen(["ctags", "-x", "--languages=Ruby", "--kinds-Ruby=cfm", "-L", "-"], "r+") do |io|
        io.puts(files)
        io.close_write
        io.read
      end

      output.lines.map do |line|
        parts = line.split(/\s+/, 4)
        { file: parts[2], name: parts[0] }
      end
    rescue Errno::ENOENT
      []
    end

    def format_symbols(symbols, budget:)
      tree = build_tree(symbols)
      render_tree(tree, budget: budget)
    end

    def build_tree(symbols)
      tree = {}
      symbols.group_by { |s| s[:file] }.each do |file, syms|
        parts = file.split("/")
        node = tree
        parts[0..-2].each { |dir| node = (node[dir + "/"] ||= {}) }
        node[parts.last] = syms.map { |s| s[:name] }.uniq
      end
      tree
    end

    def render_tree(node, indent: 0, budget:, result: String.new)
      node.each do |key, value|
        if value.is_a?(Hash)
          line = "  " * indent + key + "\n"
          return result if result.length + line.length > budget
          result << line
          render_tree(value, indent: indent + 1, budget: budget, result: result)
        else
          line = "  " * indent + key.sub(/\.rb$/, "") + ": " + value.join(" ") + "\n"
          return result if result.length + line.length > budget
          result << line
        end
      end
      result
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
