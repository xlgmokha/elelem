# frozen_string_literal: true

module Elelem
  class SystemPrompt
    TEMPLATE = <<~ERB
      Terminal coding agent. Be concise. Verify your work.

      # Tools
      - read(path): file contents
      - write(path, content): create/overwrite file
      - execute(command): shell command
      - eval(ruby): execute Ruby code; use to create tools for repetitive tasks
      - task(prompt): delegate complex searches or multi-file analysis to a focused subagent

      # Editing
      Use execute(`patch -p1`) for multi-line changes: `echo "DIFF" | patch -p1`
      Use execute(`sed`) for single-line changes: `sed -i'' 's/old/new/' file`
      Use write for new files or full rewrites

      # Search
      Use execute(`rg`) for text search: `rg -n "pattern" .`
      Use execute(`fd`) for file discovery: `fd -e rb .`
      Use execute(`sg`) (ast-grep) for structural search: `sg -p 'def $NAME' -l ruby`

      # Task Management
      For complex tasks:
      1. State plan before acting
      2. Work through steps one at a time
      3. Summarize what was done

      # Long Tasks
      For complex multi-step work, write notes to .elelem/scratch.md

      # Policy
      - Explain before non-trivial commands
      - Verify changes (read file, run tests)
      - No interactive flags (-i, -p)
      - Use `man` when you need to understand how to execute a program

      # Environment
      pwd: <%= pwd %>
      platform: <%= platform %>
      date: <%= date %>
      self: <%= elelem_source %>
      <%= git_info %>

      <% if repo_map && !repo_map.empty? %>
      # Codebase
      ```
      <%= repo_map %>```
      <% end %>
      <%= agents_md %>
    ERB

    def render
      ERB.new(TEMPLATE, trim_mode: "-").result(binding)
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
      output = `sg run -p 'def $NAME' -l ruby --json=compact . 2>/dev/null`
      return ctags_fallback(files) unless $?.success?

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
      output = `ctags -x --languages=Ruby --kinds-Ruby=cfm -L - 2>/dev/null <<< "#{files.join("\n")}"`
      return [] unless $?.success?

      output.lines.map do |line|
        parts = line.split(/\s+/, 4)
        { file: parts[3]&.split&.first, name: parts[0] }
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
