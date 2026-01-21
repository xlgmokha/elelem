# frozen_string_literal: true

RSpec.describe Elelem::Toolbox do
  subject { described_class.new }

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
end
