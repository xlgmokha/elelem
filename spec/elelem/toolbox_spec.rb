# frozen_string_literal: true

RSpec.describe Elelem::Toolbox do
  subject { described_class.new }

  before do
    subject.add("read",
      description: "Read file",
      params: { path: { type: "string" } },
      required: ["path"],
      aliases: ["open"]
    ) { |a| { content: File.read(a["path"]) } }

    subject.add("write",
      description: "Write file",
      params: { path: { type: "string" }, content: { type: "string" } },
      required: ["path", "content"]
    ) { |a| { bytes: File.write(a["path"], a["content"]) } }

    subject.add("execute",
      description: "Run shell command",
      params: { command: { type: "string" } },
      required: ["command"],
      aliases: ["bash", "sh", "exec"]
    ) { |a| { output: `#{a["command"]}` } }
  end

  describe "#to_a" do
    it "returns all tools in API format" do
      tool_names = subject.to_a.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("read", "write", "execute")
    end
  end

  describe "#run" do
    it "executes read tool" do
      result = subject.run("read", { "path" => __FILE__ })
      expect(result[:content]).to include("RSpec.describe")
    end

    it "resolves open alias to read" do
      result = subject.run("open", { "path" => __FILE__ })
      expect(result[:content]).to include("RSpec.describe")
    end

    it "returns error for unknown tools" do
      result = subject.run("nonexistent", {})
      expect(result[:error]).to include("unknown tool")
    end
  end

  describe "#exec" do
    it "escapes arguments and runs execute" do
      result = subject.exec("echo", "hello world")
      expect(result[:output]).to include("hello world")
    end

    it "handles arrays of arguments" do
      result = subject.exec("echo", ["a", "b"])
      expect(result[:output]).to include("a")
    end
  end

  describe "hooks" do
    it "runs tool-specific before hooks" do
      called = false
      subject.before("read") { |_args| called = true }
      subject.run("read", { "path" => __FILE__ })
      expect(called).to be true
    end

    it "runs tool-specific after hooks" do
      result_seen = nil
      subject.after("read") { |_args, result| result_seen = result }
      subject.run("read", { "path" => __FILE__ })
      expect(result_seen[:content]).to include("RSpec.describe")
    end

    it "runs global before hooks with tool_name" do
      tool_names = []
      subject.before { |_args, tool_name:| tool_names << tool_name }
      subject.run("read", { "path" => __FILE__ })
      subject.run("write", { "path" => "/dev/null", "content" => "" })
      expect(tool_names).to eq(["read", "write"])
    end

    it "runs global after hooks with tool_name" do
      tool_names = []
      subject.after { |_args, _result, tool_name:| tool_names << tool_name }
      subject.run("read", { "path" => __FILE__ })
      expect(tool_names).to eq(["read"])
    end

    it "runs global hooks before tool-specific hooks" do
      order = []
      subject.before { |_args, tool_name:| order << :global }
      subject.before("read") { |_args| order << :specific }
      subject.run("read", { "path" => __FILE__ })
      expect(order).to eq([:global, :specific])
    end
  end
end
