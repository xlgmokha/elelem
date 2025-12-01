# frozen_string_literal: true

RSpec.describe Elelem::Conversation do
  let(:conversation) { described_class.new }

  describe "#history_for" do
    context "with empty conversation" do
      it "returns history with mode-specific system prompt for read mode" do
        history = conversation.history_for([:read])

        expect(history.length).to eq(1)
        expect(history[0][:role]).to eq("system")
        expect(history[0][:content]).to include("You may read files on the system")
      end

      it "returns history with mode-specific system prompt for write mode" do
        history = conversation.history_for([:write])

        expect(history[0][:content]).to include("You may write files on the system")
      end

      it "returns history with mode-specific system prompt for execute mode" do
        history = conversation.history_for([:execute])

        expect(history[0][:content]).to include("You may execute shell commands on the system")
      end

      it "returns history with mode-specific system prompt for read+write mode" do
        history = conversation.history_for([:read, :write])

        expect(history[0][:content]).to include("You may read and write files on the system")
      end

      it "returns history with mode-specific system prompt for read+execute mode" do
        history = conversation.history_for([:read, :execute])

        expect(history[0][:content]).to include("You may execute shell commands and read files on the system")
      end

      it "returns history with mode-specific system prompt for write+execute mode" do
        history = conversation.history_for([:write, :execute])

        expect(history[0][:content]).to include("You may execute shell commands and write files on the system")
      end

      it "returns history with mode-specific system prompt for all tools mode" do
        history = conversation.history_for([:read, :write, :execute])

        expect(history[0][:content]).to include("You may read files, write files and execute shell commands on the system")
      end

      it "returns base system prompt for unknown mode" do
        history = conversation.history_for([:unknown])

        expect(history[0][:content]).not_to include("Read and analyze")
        expect(history[0][:content]).not_to include("Write clean")
      end

      it "returns base system prompt for empty mode" do
        history = conversation.history_for([])

        expect(history[0][:role]).to eq("system")
        expect(history[0][:content]).to be_a(String)
      end
    end

    context "with mode order independence" do
      it "returns same prompt for [:read, :write] and [:write, :read]" do
        history1 = conversation.history_for([:read, :write])
        history2 = conversation.history_for([:write, :read])

        expect(history1[0][:content]).to eq(history2[0][:content])
      end

      it "returns same prompt for [:read, :execute] and [:execute, :read]" do
        history1 = conversation.history_for([:read, :execute])
        history2 = conversation.history_for([:execute, :read])

        expect(history1[0][:content]).to eq(history2[0][:content])
      end

      it "returns same prompt for all permutations of [:read, :write, :execute]" do
        history1 = conversation.history_for([:read, :write, :execute])
        history2 = conversation.history_for([:execute, :read, :write])
        history3 = conversation.history_for([:write, :execute, :read])

        expect(history1[0][:content]).to eq(history2[0][:content])
        expect(history2[0][:content]).to eq(history3[0][:content])
      end
    end

    context "with populated conversation" do
      before do
        conversation.add(role: :user, content: "Hello")
        conversation.add(role: :assistant, content: "Hi there")
      end

      it "preserves all conversation items" do
        history = conversation.history_for([:read])

        expect(history.length).to eq(3)
        expect(history[1][:role]).to eq(:user)
        expect(history[1][:content]).to eq("Hello")
        expect(history[2][:role]).to eq(:assistant)
        expect(history[2][:content]).to eq("Hi there")
      end

      it "updates system prompt without mutating original" do
        original_items = conversation.instance_variable_get(:@items)
        original_system_content = original_items[0][:content]

        history = conversation.history_for([:read])

        expect(history[0][:content]).not_to eq(original_system_content)
        expect(original_items[0][:content]).to eq(original_system_content)
      end

      it "returns a copy, not the original array" do
        history = conversation.history_for([:read])
        original_items = conversation.instance_variable_get(:@items)

        expect(history).not_to be(original_items)
      end
    end
  end

  describe "#add" do
    it "adds user message to conversation" do
      conversation.add(role: :user, content: "test message")
      history = conversation.history_for([])

      expect(history.length).to eq(2)
      expect(history[1][:content]).to eq("test message")
    end

    it "merges consecutive messages with same role" do
      conversation.add(role: :user, content: "part 1")
      conversation.add(role: :user, content: "part 2")
      history = conversation.history_for([])

      expect(history.length).to eq(2)
      expect(history[1][:content]).to eq("part 1part 2")
    end

    it "ignores nil content" do
      conversation.add(role: :user, content: nil)
      history = conversation.history_for([])

      expect(history.length).to eq(1)
    end

    it "ignores empty content" do
      conversation.add(role: :user, content: "")
      history = conversation.history_for([])

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
      history = conversation.history_for([])

      expect(history.length).to eq(1)
      expect(history[0][:role]).to eq("system")
    end
  end

  describe "#dump" do
    it "returns JSON representation with mode-specific prompt" do
      conversation.add(role: :user, content: "test")
      json = conversation.dump([:read])

      parsed = JSON.parse(json)
      expect(parsed).to be_an(Array)
      expect(parsed.length).to eq(2)
      expect(parsed[0]["content"]).to include("You may read files on the system")
    end
  end
end
