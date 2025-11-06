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
end
