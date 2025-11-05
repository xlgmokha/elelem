# frozen_string_literal: true

module Elelem
  class Agent
    attr_reader :conversation, :client, :tools

    def initialize(client)
      @conversation = Conversation.new
      @client = client

      exec_tool = build_tool("execute", "Execute shell commands. Returns stdout, stderr, and exit code. Use for: checking system state, running tests, managing services. Common Unix tools available: git, bash, grep, etc. Tip: Check exit_status in response to determine success.", { cmd: { type: "string" }, args: { type: "array", items: { type: "string" } }, env: { type: "object", additionalProperties: { type: "string" } }, cwd: { type: "string", description: "Working directory for command execution (defaults to current directory if not specified)" }, stdin: { type: "string" } }, ["cmd"])
      grep_tool = build_tool("grep", "Search all git-tracked files using git grep. Returns file paths with matching line numbers. Use this to discover where code/configuration exists before reading files. Examples: search 'def method_name' to find method definitions. Much faster than reading multiple files.", { query: { type: "string" } }, ["query"])
      ls_tool = build_tool("list", "List all git-tracked files in the repository, optionally filtered by path. Use this to explore project structure or find files in a directory. Returns relative paths from repo root. Tip: Use this before reading if you need to discover what files exist.", { path: { type: "string" } })
      patch_tool = build_tool("patch", "Apply a unified diff patch via 'git apply'. Use this for surgical edits to existing files rather than rewriting entire files. Generates proper git diffs. Format: standard unified diff with --- and +++ headers. Tip: More efficient than write for small changes to large files.", { diff: { type: "string" } }, ["diff"])
      read_tool = build_tool("read", "Read complete contents of a file. Requires exact file path. Use grep or list first if you don't know the path. Best for: understanding existing code, reading config files, reviewing implementation details. Tip: For large files, grep first to confirm relevance.", { path: { type: "string" } }, ["path"])
      write_tool = build_tool("write", "Write complete file contents (overwrites existing files). Creates parent directories automatically. Best for: creating new files, replacing entire file contents. For small edits to existing files, consider using patch instead.", { path: { type: "string" }, content: { type: "string" } }, ["path", "content"])

      @tools = {
        read: [grep_tool, ls_tool, read_tool],
        write: [patch_tool, write_tool],
        execute: [exec_tool]
      }
    end

    def repl
      mode = Set.new([:read])

      loop do
        input = ask?("User> ")
        break if input.nil?
        if input.start_with?("/")
          case input
          when "/mode auto"
            mode = Set[:read, :write, :execute]
            puts "  → Mode: auto (all tools enabled)"
          when "/mode build"
            mode = Set[:read, :write]
            puts "  → Mode: build (read + write)"
          when "/mode plan"
            mode = Set[:read]
            puts "  → Mode: plan (read-only)"
          when "/mode verify"
            mode = Set[:read, :execute]
            puts "  → Mode: verify (read + execute)"
          when "/mode"
            puts "  Mode: #{mode.to_a.inspect}"
            puts "  Tools: #{tools_for(mode).map { |t| t.dig(:function, :name) }}"
          when "/exit" then exit
          when "/clear"
            conversation.clear
            puts "  → Conversation cleared"
          when "/context" then puts conversation.dump
          else
            puts help_banner
          end
        else
          conversation.set_system_prompt(system_prompt_for(mode))
          conversation.add(role: :user, content: input)
          result = execute_turn(conversation.history, tools: tools_for(mode))
          conversation.add(role: result[:role], content: result[:content])
        end
      end
    end

    private

    def ask?(text)
      Reline.readline(text, true)&.strip
    end

    def help_banner
      <<~HELP
  /mode auto build plan verify
  /clear
  /context
  /exit
  /help
      HELP
    end

    def tools_for(modes)
      modes.map { |mode| tools[mode] }.flatten
    end

    def system_prompt_for(mode)
      base = "You are a reasoning coding and system agent."

      case mode.to_a.sort
      when [:read]
        "#{base}\n\nRead and analyze. Understand before suggesting action."
      when [:write]
        "#{base}\n\nWrite clean, thoughtful code."
      when [:execute]
        "#{base}\n\nUse shell commands creatively to understand and manipulate the system."
      when [:read, :write]
        "#{base}\n\nFirst understand, then build solutions that integrate well."
      when [:read, :execute]
        "#{base}\n\nUse commands to deeply understand the system."
      when [:write, :execute]
        "#{base}\n\nCreate and execute freely. Have fun. Be kind."
      when [:read, :write, :execute]
        "#{base}\n\nYou have all tools. Use them wisely."
      else
        base
      end
    end

    def format_tool_call(name, args)
      case name
      when "execute"
        cmd = args["cmd"]
        cmd_args = args["args"] || []
        cmd_args.empty? ? cmd : "#{cmd} #{cmd_args.join(' ')}"
      when "grep" then "grep(#{args["query"]})"
      when "list" then "list(#{args["path"] || "."})"
      when "patch" then "patch(#{args["diff"]&.lines&.count || 0} lines)"
      when "read" then "read(#{args["path"]})"
      when "write" then "write(#{args["path"]})"
      else
        "#{name}(#{args.to_s[0...50]})"
      end
    end

    def execute_turn(messages, tools:)
      turn_context = []

      loop do
        content = ""
        tool_calls = []

        print "Thinking..."
        client.chat(messages + turn_context, tools) do |chunk|
          msg = chunk["message"]
          if msg
            if msg["content"] && !msg["content"].empty?
              print "\r\e[K" if content.empty?
              print msg["content"]
              content += msg["content"]
            end

            tool_calls += msg["tool_calls"] if msg["tool_calls"]
          end
        end

        puts
        turn_context << { role: "assistant", content: content, tool_calls: tool_calls }.compact

        if tool_calls.any?
          tool_calls.each do |call|
            name = call.dig("function", "name")
            args = call.dig("function", "arguments")

            puts "Tool> #{format_tool_call(name, args)}"
            result = run_tool(name, args)
            turn_context << { role: "tool", content: JSON.dump(result) }
          end

          tool_calls = []
          next
        end

        return { role: "assistant", content: content }
      end
    end

    def run_exec(command, args: [], env: {}, cwd: Dir.pwd, stdin: nil)
      cmd = command.is_a?(Array) ? command.first : command
      cmd_args = command.is_a?(Array) ? command[1..] + args : args
      stdout, stderr, status = Open3.capture3(env, cmd, *cmd_args, chdir: cwd, stdin_data: stdin)
      {
        "exit_status" => status.exitstatus,
        "stdout" => stdout.to_s,
        "stderr" => stderr.to_s
      }
    end

    def expand_path(path)
      Pathname.new(path).expand_path
    end

    def read_file(path)
      full_path = expand_path(path)
      full_path.exist? ? { content: full_path.read } : { error: "File not found: #{path}" }
    end

    def write_file(path, content)
      full_path = expand_path(path)
      FileUtils.mkdir_p(full_path.dirname)
      { bytes_written: full_path.write(content) }
    end

    def run_tool(name, args)
      case name
      when "execute" then run_exec(args["cmd"], args: args["args"] || [], env: args["env"] || {}, cwd: args["cwd"].to_s.empty? ? Dir.pwd : args["cwd"], stdin: args["stdin"])
      when "grep" then run_exec("git", args: ["grep", "-nI", args["query"]])
      when "list" then run_exec("git", args: args["path"] ? ["ls-files", "--", args["path"]] : ["ls-files"])
      when "patch" then run_exec("git", args: ["apply", "--index", "--whitespace=nowarn", "-p1"], stdin: args["diff"])
      when "read" then read_file(args["path"])
      when "write" then write_file(args["path"], args["content"])
      else
        { error: "Unknown tool", name: name, args: args }
      end
    rescue => error
      { error: error.message, name: name, args: args }
    end

    def build_tool(name, description, properties, required = [])
      {
        type: "function",
        function: {
          name: name,
          description: description,
          parameters: {
            type: "object",
            properties: properties,
            required: required
          }
        }
      }
    end
  end
end
