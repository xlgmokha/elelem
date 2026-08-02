# frozen_string_literal: true

RSpec.describe Elelem::Permissions do
  subject { described_class.new }

  let(:terminal) { double(ask: nil, interactive?: false) }

  describe "#check" do
    context "with default allow policies" do
      it "allows read without prompting" do
        expect(subject.check("read", {}, terminal: terminal)).to be true
        expect(terminal).not_to have_received(:ask)
      end
    end

    context "with deny policy" do
      subject { described_class.new(rules: { write: :deny }) }

      it { expect { subject.check("write", {}, terminal: terminal) }.to raise_error(/Permission denied/) }
    end

    context "with ask policy on a non-interactive terminal" do
      it "returns true without prompting" do
        expect(subject.check("execute", {}, terminal: terminal)).to be true
        expect(terminal).not_to have_received(:ask)
      end
    end

    context "with ask policy on an interactive terminal" do
      let(:terminal) { double(ask: answer, interactive?: true) }

      context "when approved" do
        let(:answer) { "y" }

        it "prompts and returns true" do
          expect(subject.check("execute", {}, terminal: terminal)).to be true
          expect(terminal).to have_received(:ask)
        end
      end

      context "when denied" do
        let(:answer) { "n" }

        it { expect { subject.check("execute", {}, terminal: terminal) }.to raise_error(/User denied permission/) }
      end
    end
  end
end
