# frozen_string_literal: true

RSpec.describe Elelem::Agent do
  let(:toolbox) { Elelem::Toolbox.new }
  let(:fake_client) { instance_double(Net::Llm::Ollama, model: "test-model") }

  before do
    allow(Net::Llm::Ollama).to receive(:new).and_return(fake_client)
  end

  describe "slash commands" do
    describe "/mode" do
      it "shows help when called without arguments" do
        terminal = Elelem::FakeTerminal.new(inputs: ["/mode", nil])
        agent = described_class.new("ollama", nil, toolbox, terminal: terminal)

        agent.repl

        expect(terminal.output).to include("  Usage: /mode [auto|build|plan|verify]")
      end

      it "switches to auto mode" do
        terminal = Elelem::FakeTerminal.new(inputs: ["/mode auto", nil])
        agent = described_class.new("ollama", nil, toolbox, terminal: terminal)

        agent.repl

        expect(terminal.output).to include("  → Mode: auto (all tools enabled)")
      end

      it "switches to build mode" do
        terminal = Elelem::FakeTerminal.new(inputs: ["/mode build", nil])
        agent = described_class.new("ollama", nil, toolbox, terminal: terminal)

        agent.repl

        expect(terminal.output).to include("  → Mode: build (read + write)")
      end

      it "switches to plan mode" do
        terminal = Elelem::FakeTerminal.new(inputs: ["/mode plan", nil])
        agent = described_class.new("ollama", nil, toolbox, terminal: terminal)

        agent.repl

        expect(terminal.output).to include("  → Mode: plan (read-only)")
      end

      it "switches to verify mode" do
        terminal = Elelem::FakeTerminal.new(inputs: ["/mode verify", nil])
        agent = described_class.new("ollama", nil, toolbox, terminal: terminal)

        agent.repl

        expect(terminal.output).to include("  → Mode: verify (read + execute)")
      end
    end

    describe "/clear" do
      it "clears the conversation" do
        terminal = Elelem::FakeTerminal.new(inputs: ["/clear", nil])
        agent = described_class.new("ollama", nil, toolbox, terminal: terminal)
        agent.conversation.add(role: :user, content: "hello")

        agent.repl

        expect(terminal.output).to include("  → Conversation cleared")
      end
    end

    describe "/env" do
      it "shows help and env vars when called without arguments" do
        terminal = Elelem::FakeTerminal.new(inputs: ["/env", nil])
        agent = described_class.new("ollama", nil, toolbox, terminal: terminal)

        agent.repl

        expect(terminal.output).to include("  Usage: /env VAR cmd...")
        expect(terminal.output.any? { |line| line.include?("ANTHROPIC_API_KEY") }).to be true
      end

      it "sets environment variable from command output" do
        terminal = Elelem::FakeTerminal.new(inputs: ["/env TEST_VAR echo hello", nil])
        agent = described_class.new("ollama", nil, toolbox, terminal: terminal)

        agent.repl

        expect(terminal.output).to include("  → Set TEST_VAR")
        expect(ENV["TEST_VAR"]).to eq("hello")
      end
    end

    describe "/help" do
      it "shows help banner" do
        terminal = Elelem::FakeTerminal.new(inputs: ["/help", nil])
        agent = described_class.new("ollama", nil, toolbox, terminal: terminal)

        agent.repl

        expect(terminal.output.join).to include("/env VAR cmd...")
        expect(terminal.output.join).to include("/mode auto build plan verify")
      end
    end
  end
end
