# frozen_string_literal: true

RSpec.describe Elelem::Agent do
  let(:mock_client) { double("client", model: "test-model") }
  let(:agent) do
    agent = described_class.allocate
    agent.instance_variable_set(:@conversation, Elelem::Conversation.new)
    agent.instance_variable_set(:@provider, "ollama")
    agent.instance_variable_set(:@toolbox, Elelem::Toolbox.new)
    agent.instance_variable_set(:@client, mock_client)
    agent
  end

  describe "#initialize" do
    it "creates a new conversation" do
      expect(agent.conversation).to be_a(Elelem::Conversation)
    end

    it "stores the client" do
      expect(agent.client).to eq(mock_client)
    end

    it "initializes toolbox with all tools" do
      tool_names = agent.toolbox.tools.map { |t| t.dig(:function, :name) }
      expect(tool_names).to include("read", "write", "exec", "grep", "list")
    end
  end
end
