# frozen_string_literal: true

RSpec.describe Elelem::Agent do
  let(:mock_client) { double("client") }
  let(:agent) { described_class.new(mock_client) }

  describe "#initialize" do
    it "creates a new conversation" do
      expect(agent.conversation).to be_a(Elelem::Conversation)
    end

    it "stores the client" do
      expect(agent.client).to eq(mock_client)
    end

    it "initializes tools for all modes" do
      expect(agent.tools[:read]).to be_an(Array)
      expect(agent.tools[:write]).to be_an(Array)
      expect(agent.tools[:execute]).to be_an(Array)
    end
  end

  describe "#tools_for" do
    it "returns read tools for read mode" do
      mode = Set[:read]
      tools = agent.send(:tools_for, mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("grep", "list", "read")
      expect(tool_names).not_to include("write", "patch", "execute")
    end

    it "returns write tools for write mode" do
      mode = Set[:write]
      tools = agent.send(:tools_for, mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("patch", "write")
      expect(tool_names).not_to include("grep", "execute")
    end

    it "returns execute tools for execute mode" do
      mode = Set[:execute]
      tools = agent.send(:tools_for, mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("execute")
      expect(tool_names).not_to include("grep", "write")
    end

    it "returns all tools for auto mode" do
      mode = Set[:read, :write, :execute]
      tools = agent.send(:tools_for, mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("grep", "list", "read", "patch", "write", "execute")
    end

    it "returns combined tools for build mode" do
      mode = Set[:read, :write]
      tools = agent.send(:tools_for, mode)

      tool_names = tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("grep", "read", "write", "patch")
      expect(tool_names).not_to include("execute")
    end
  end

  describe "integration with conversation" do
    it "conversation uses mode-aware prompts" do
      conversation = agent.conversation
      conversation.add(role: :user, content: "test message")

      read_history = conversation.history_for([:read])
      write_history = conversation.history_for([:write])

      expect(read_history[0][:content]).to include("Read and analyze")
      expect(write_history[0][:content]).to include("Write clean, thoughtful code")
      expect(read_history[0][:content]).not_to eq(write_history[0][:content])
    end
  end
end
