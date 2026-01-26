# frozen_string_literal: true

RSpec.describe Elelem::Permissions do
  subject { described_class.new }

  let(:terminal) { double(ask: nil) }

  describe "#check" do
    context "with default allow policies" do
      it "allows read without prompting" do
        expect(subject.check("read", {}, terminal: terminal)).to be true
        expect(terminal).not_to have_received(:ask)
      end
    end

    context "with deny policy" do
      it "raises an error" do
        permissions = described_class.new
        permissions.instance_variable_set(:@rules, { write: :deny })
        expect { permissions.check("write", {}, terminal: terminal) }.to raise_error(/Permission denied/)
      end
    end

    context "with ask policy in non-TTY mode" do
      before { allow($stdin).to receive(:tty?).and_return(false) }

      it "returns true without prompting" do
        expect(subject.check("execute", {}, terminal: terminal)).to be true
      end
    end
  end
end
