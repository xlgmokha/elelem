# frozen_string_literal: true

RSpec.describe Elelem::Commands do
  subject(:commands) { described_class.new }

  describe "#register" do
    context "when registering a command without args" do
      before do
        @called = false
        commands.register("example") { @called = true }
      end

      it "executes the command" do
        expect(commands.run("example")).to be(true)
        expect(@called).to be(true)
      end
    end

    context "when registering a command with args" do
      before do
        @called = false
        @args = {}
        commands.register("example") { |args| @called = true; @args = args }
      end

      it "executes the command with args" do
        args = { ts: Time.now.to_i }
        expect(commands.run("example", args)).to be(true)
        expect(@called).to be(true)
        expect(@args).to eq(args)
      end
    end

    it "stores description" do
      commands.register("test", description: "Test command") { }
      expect(commands.include?("test")).to be true
    end
  end

  describe "#command_for" do
    context "when the command is registered" do
      subject(:command) { commands.command_for("raise") }

      before do
        commands.register("raise", description: "Raises an error", completions: ['heck']) do |args|
          raise args.inspect
        end
      end

      it { expect(command).not_to be_nil }
      it { expect(command&.name).to eq("raise") }
      it { expect(command&.description).to eq("Raises an error") }
      it { expect(command&.completions).to match_array(['heck']) }
    end
  end

  describe "#run" do
    it "returns true when command exists" do
      commands.register("test") { }
      expect(commands.run("test")).to be true
    end

    it "returns false when command does not exist" do
      expect(commands.run("nonexistent")).to be false
    end
  end

  describe "#names" do
    it "returns command names with slash prefix" do
      commands.register("exit") { }
      commands.register("help") { }
      expect(commands.names).to contain_exactly("/exit", "/help")
    end
  end

  describe "#include?" do
    it "returns true for registered commands" do
      commands.register("test") { }
      expect(commands.include?("test")).to be true
    end

    it "returns false for unregistered commands" do
      expect(commands.include?("test")).to be false
    end
  end
end
