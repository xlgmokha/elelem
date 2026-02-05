# frozen_string_literal: true

require "spec_helper"

RSpec.describe Elelem::Terminal do
  subject(:terminal) { described_class.new(quiet: true) }

  describe "#gap" do
    it "outputs newline when not at line start" do
      terminal.instance_variable_set(:@at_line_start, false)
      expect { terminal.gap }.to output("\n").to_stdout
    end

    it "outputs nothing when already at line start" do
      terminal.instance_variable_set(:@at_line_start, true)
      expect { terminal.gap }.not_to output.to_stdout
    end

    it "is idempotent - calling twice produces one newline" do
      terminal.instance_variable_set(:@at_line_start, false)
      expect { terminal.gap; terminal.gap }.to output("\n").to_stdout
    end

    it "stops dots thread when called" do
      dots_thread = double("thread")
      allow(dots_thread).to receive(:kill)
      terminal.instance_variable_set(:@dots_thread, dots_thread)
      terminal.gap
      expect(terminal.instance_variable_get(:@dots_thread)).to be_nil
    end
  end

  describe "@at_line_start tracking" do
    it "starts true (cursor at line start)" do
      expect(terminal.instance_variable_get(:@at_line_start)).to be true
    end

    it "becomes true after say" do
      terminal.instance_variable_set(:@at_line_start, false)
      terminal.say("hello")
      expect(terminal.instance_variable_get(:@at_line_start)).to be true
    end

    it "becomes false after print" do
      terminal.instance_variable_set(:@at_line_start, true)
      terminal.print("hello")
      expect(terminal.instance_variable_get(:@at_line_start)).to be false
    end

    it "becomes true after newline" do
      terminal.instance_variable_set(:@at_line_start, false)
      terminal.newline
      expect(terminal.instance_variable_get(:@at_line_start)).to be true
    end
  end
end
