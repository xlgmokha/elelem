# frozen_string_literal: true

module Elelem
  module Verifiers
    SYNTAX = {
      ".rb" => "ruby -c %{path}",
      ".py" => "python -m py_compile %{path}",
      ".go" => "go vet %{path}",
      ".rs" => "cargo check --quiet",
      ".ts" => "npx tsc --noEmit %{path}",
      ".js" => "node --check %{path}",
    }.freeze

    def self.for(path)
      return [] unless path

      cmds = []
      ext = File.extname(path)
      cmds << (SYNTAX[ext] % { path: path }) if SYNTAX[ext]
      cmds << test_runner
      cmds.compact
    end

    def self.test_runner
      %w[bin/test script/test].find { |s| File.executable?(s) }
    end
  end

  Plugins.register(:verify) do |toolbox|
    toolbox.after("write") do |_args, result|
      next if result[:error]

      Verifiers.for(result[:path]).each do |cmd|
        $stdout.puts "\n  -> verify: #{cmd}"
        v = Elelem.sh("bash", args: ["-c", cmd]) { |x| $stdout.print(x) }
        status = v[:exit_status] == 0 ? "ok" : "FAIL"
        $stdout.puts "  #{status} #{cmd}"
        if v[:exit_status] != 0
          $stdout.puts v[:content].lines.first(5).map { |l| "    #{l}" }.join
          break
        end
      end
    end
  end
end
