# frozen_string_literal: true

RSpec.describe Elelem::Conversation do
  let(:conversation) { described_class.new }

  describe "#history" do
    it "returns history with system prompt" do
      history = conversation.history

      expect(history.length).to eq(1)
      expect(history[0][:role]).to eq("system")
      expect(history[0][:content]).to be_a(String)
    end

    context "with populated conversation" do
      before do
        conversation.add(role: :user, content: "Hello")
        conversation.add(role: :assistant, content: "Hi there")
      end

      it "preserves all conversation items" do
        history = conversation.history

        expect(history.length).to eq(3)
        expect(history[1][:role]).to eq(:user)
        expect(history[1][:content]).to eq("Hello")
        expect(history[2][:role]).to eq(:assistant)
        expect(history[2][:content]).to eq("Hi there")
      end

      it "returns a copy, not the original array" do
        history = conversation.history
        original_items = conversation.instance_variable_get(:@items)

        expect(history).not_to be(original_items)
      end
    end
  end

  describe "#add" do
    it "adds user message to conversation" do
      conversation.add(role: :user, content: "test message")
      history = conversation.history

      expect(history.length).to eq(2)
      expect(history[1][:content]).to eq("test message")
    end

    it "merges consecutive messages with same role" do
      conversation.add(role: :user, content: "part 1")
      conversation.add(role: :user, content: "part 2")
      history = conversation.history

      expect(history.length).to eq(2)
      expect(history[1][:content]).to eq("part 1part 2")
    end

    it "ignores nil content" do
      conversation.add(role: :user, content: nil)
      history = conversation.history

      expect(history.length).to eq(1)
    end

    it "ignores empty content" do
      conversation.add(role: :user, content: "")
      history = conversation.history

      expect(history.length).to eq(1)
    end

    it "raises error for unknown role" do
      expect {
        conversation.add(role: :unknown, content: "test")
      }.to raise_error(/unknown role/)
    end
  end

  describe "#clear" do
    it "resets conversation to default context" do
      conversation.add(role: :user, content: "test")
      conversation.clear
      history = conversation.history

      expect(history.length).to eq(1)
      expect(history[0][:role]).to eq("system")
    end
  end

  describe "#dump" do
    it "returns markdown representation" do
      conversation.add(role: :user, content: "test")
      result = conversation.dump

      expect(result).to include("## System")
      expect(result).to include("## User")
    end
  end
end
