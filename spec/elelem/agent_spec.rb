# frozen_string_literal: true

RSpec.describe Elelem::Agent do
  let(:mock_client) { double("client") }
  let(:agent) { described_class.new(mock_client, Elelem::Toolbox.new) }

  describe "#initialize" do
    it "creates a new conversation" do
      expect(agent.conversation).to be_a(Elelem::Conversation)
    end

    it "stores the client" do
      expect(agent.client).to eq(mock_client)
    end

    it "initializes tools for all modes" do
      expect(agent.toolbox.tools[:read]).to be_an(Array)
      expect(agent.toolbox.tools[:write]).to be_an(Array)
      expect(agent.toolbox.tools[:execute]).to be_an(Array)
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
