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
end
