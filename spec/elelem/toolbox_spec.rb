# frozen_string_literal: true

RSpec.describe Elelem::Toolbox do
  subject { described_class.new }

  describe "#to_h" do
    it "returns all tools in API format" do
      tool_names = subject.to_h.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("read", "write", "exec", "web_fetch", "web_search", "eval")
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

    it "executes eval tool" do
      result = subject.run("eval", { "ruby" => "2 + 2" })
      expect(result[:result]).to eq(4)
    end
  end
end
