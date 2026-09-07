# frozen_string_literal: true

require "spec_helper"

RSpec.describe Elelem::NullOutput do
  subject(:null_output) { described_class.new }

  it "is silent" do
    expect { null_output.say("hello") }.not_to output("hello").to_stdout
  end

  it "responds to every Output method" do
    expect(null_output).to respond_to(:say, :print, :thinking, :waiting, :doing, :display_file)
  end
end
