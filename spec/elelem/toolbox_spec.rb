# frozen_string_literal: true

RSpec.describe Elelem::Toolbox do
  subject { described_class.new }

  describe "#tools" do
    it "returns all tools" do
      tool_names = subject.tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("grep", "list", "read", "patch", "write", "exec", "fetch", "web_search", "eval")
    end
  end

  describe "aliases" do
    it "resolves web and get aliases to fetch" do
      expect(Elelem::Toolbox::TOOL_ALIASES["web"]).to eq("fetch")
      expect(Elelem::Toolbox::TOOL_ALIASES["get"]).to eq("fetch")
    end

    it "resolves duckduckgo alias to web_search" do
      expect(Elelem::Toolbox::TOOL_ALIASES["duckduckgo"]).to eq("web_search")
    end

    it "resolves bash alias to exec" do
      expect(Elelem::Toolbox::TOOL_ALIASES["bash"]).to eq("exec")
    end
  end

  describe "#run_tool" do
    it "executes tools" do
      result = subject.run_tool("read", { "path" => __FILE__ })
      expect(result[:content]).to include("RSpec.describe")
    end

    it "resolves aliases" do
      result = subject.run_tool("open", { "path" => __FILE__ })
      expect(result[:content]).to include("RSpec.describe")
    end

    it "returns unknown tool error for non-existent tools" do
      result = subject.run_tool("nonexistent", {})
      expect(result[:error]).to include("Unknown tool")
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

      expect(subject.tools).to include(hash_including({
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
