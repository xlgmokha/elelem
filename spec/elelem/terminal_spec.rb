# frozen_string_literal: true

require "spec_helper"

RSpec.describe Elelem::Terminal do
  subject(:terminal) { described_class.new(quiet: false) }

  describe "#gap" do
    it "outputs newline after print" do
      expect {
        terminal.print("hello")
        terminal.gap
      }.to output("hello\n").to_stdout
    end

    it "outputs nothing after say" do
      expect {
        terminal.say("hello")
        terminal.gap
      }.to output("hello\n").to_stdout
    end

    it "outputs nothing after newline" do
      expect {
        terminal.print("hello")
        terminal.newline
        terminal.gap
      }.to output("hello\n").to_stdout
    end

    it "is idempotent" do
      expect {
        terminal.print("hello")
        terminal.gap
        terminal.gap
        terminal.gap
      }.to output("hello\n").to_stdout
    end

    it "outputs nothing in quiet mode" do
      quiet_terminal = described_class.new(quiet: true)
      expect {
        quiet_terminal.print("hello")
        quiet_terminal.gap
      }.not_to output.to_stdout
    end
  end

  describe "#say" do
    it "outputs text with newline" do
      expect { terminal.say("hello") }.to output("hello\n").to_stdout
    end

    it "outputs nothing for blank text" do
      expect { terminal.say("") }.not_to output.to_stdout
    end

    it "outputs nothing in quiet mode" do
      quiet_terminal = described_class.new(quiet: true)
      expect { quiet_terminal.say("hello") }.not_to output.to_stdout
    end
  end

  describe "#print" do
    it "outputs text without newline" do
      expect { terminal.print("hello") }.to output("hello").to_stdout
    end

    it "outputs nothing for blank text" do
      expect { terminal.print("") }.not_to output.to_stdout
    end

    it "outputs nothing in quiet mode" do
      quiet_terminal = described_class.new(quiet: true)
      expect { quiet_terminal.print("hello") }.not_to output.to_stdout
    end
  end

  describe "#newline" do
    it "outputs blank line" do
      expect { terminal.newline }.to output("\n").to_stdout
    end

    it "outputs multiple blank lines" do
      expect { terminal.newline(n: 3) }.to output("\n\n\n").to_stdout
    end

    it "outputs nothing in quiet mode" do
      quiet_terminal = described_class.new(quiet: true)
      expect { quiet_terminal.newline }.not_to output.to_stdout
    end
  end

  describe "#waiting" do
    around do |example|
      original = $stdout
      $stdout = StringIO.new
      example.run
    ensure
      $stdout = original
    end

    def dots_thread
      terminal.instance_variable_get(:@dots_thread)
    end

    it "stops dots when say receives blank text" do
      terminal.waiting
      thread = dots_thread
      terminal.say(nil)
      expect(thread.join(1)).to eq(thread)
    end

    it "stops dots when print receives blank text" do
      terminal.waiting
      thread = dots_thread
      terminal.print(nil)
      expect(thread.join(1)).to eq(thread)
    end

    it "kills the previous dots thread when called again" do
      terminal.waiting
      previous = dots_thread
      terminal.waiting
      expect(previous.join(1)).to eq(previous)
    end
  end

  describe "spacing consistency" do
    it "produces single blank line between sections regardless of method used" do
      expect {
        terminal.say("section 1")
        terminal.gap
        terminal.say("section 2")
      }.to output("section 1\nsection 2\n").to_stdout
    end

    it "produces single blank line after print then gap" do
      expect {
        terminal.print("partial")
        terminal.gap
        terminal.say("next")
      }.to output("partial\nnext\n").to_stdout
    end
  end
end
