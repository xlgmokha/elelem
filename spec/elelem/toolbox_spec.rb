# frozen_string_literal: true
#
RSpec.describe Elelem::Toolbox do
  subject { described_class.new }

  describe "#tools_for" do
    it "returns read tools for read mode" do
      mode = Set[:read]
      tools = subject.tools_for(mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("grep", "list", "read")
      expect(tool_names).not_to include("write", "patch", "execute")
    end

    it "returns write tools for write mode" do
      mode = Set[:write]
      tools = subject.tools_for(mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("patch", "write")
      expect(tool_names).not_to include("grep", "execute")
    end

    it "returns execute tools for execute mode" do
      mode = Set[:execute]
      tools = subject.tools_for(mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("execute")
      expect(tool_names).not_to include("grep", "write")
    end

    it "returns all tools for auto mode" do
      mode = Set[:read, :write, :execute]
      tools = subject.tools_for(mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("grep", "list", "read", "patch", "write", "execute")
    end

    it "returns combined tools for build mode" do
      mode = Set[:read, :write]
      tools = subject.tools_for(mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("grep", "read", "write", "patch")
      expect(tool_names).not_to include("execute")
    end
  end

  describe "meta-programming with eval tool" do
    it "allows LLM to register new tools dynamically" do
      subject.run_tool("eval", {
        "ruby" => <<~RUBY
          register_tool("hello", "Says hello to a name", { name: { type: "string" } }, ["name"]) do |args|
            { greeting: "Hello, " + args['name']+ "!" }
          end
        RUBY
      })

      expect(subject.tools_for(:execute)).to include(hash_including({
        type: "function",
        function: {
          name: "hello",
          description: "Says hello to a name",
          parameters: {
            type: "object",
            properties: { name: { type: "string" } },
            required: ["name"]
          }
        }
      }))
    end

    it "allows LLM to call dynamically created tools" do
      subject.run_tool("eval", {
        "ruby" => <<~RUBY
          register_tool("add", "Adds two numbers", { a: { type: "number" }, b: { type: "number" } }, ["a", "b"]) do |args|
            { sum: args["a"] + args["b"] }
          end
        RUBY
      })

      result = subject.run_tool("add", { "a" => 5, "b" => 3 })
      expect(result[:sum]).to eq(8)
    end

    it "allows LLM to inspect tool schemas" do
      result = subject.run_tool("eval", { "ruby" => "tool_schema('read')" })
      expect(result[:result]).to be_a(Hash)
      expect(result[:result].dig(:function, :name)).to eq("read")
    end

    it "executes arbitrary Ruby code" do
      result = subject.run_tool("eval", { "ruby" => "2 + 2" })
      expect(result[:result]).to eq(4)
    end

    it "handles errors gracefully" do
      result = subject.run_tool("eval", { "ruby" => "undefined_variable" })
      expect(result[:error]).to include("undefined")
      expect(result[:backtrace]).to be_an(Array)
    end
  end
end
