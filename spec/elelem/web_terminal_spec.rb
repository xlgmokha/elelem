# frozen_string_literal: true

RSpec.describe Elelem::WebTerminal do
  subject { described_class.new }

  let(:events) { subject.subscribe }

  before { events }

  def drain(queue = events)
    [].tap { |collected| collected << queue.pop until queue.empty? }
  end

  describe "#interactive?" do
    it { expect(subject).to be_interactive }
  end

  describe "#quiet?" do
    it { expect(subject).not_to be_quiet }
  end

  describe "#say" do
    it "emits content" do
      subject.say("hello")
      expect(drain).to eq([{ type: "content", text: "hello" }])
    end

    it "ignores blank text" do
      subject.say("  ")
      subject.say(nil)
      expect(drain).to be_empty
    end

    it "strips ANSI colour codes meant for a terminal" do
      subject.say("+ \e[36mexecute\e[0m(...)")
      expect(drain).to eq([{ type: "content", text: "+ execute(...)" }])
    end
  end

  describe "#think" do
    it "emits thinking and returns nil so #print stays a no-op" do
      expect(subject.think("pondering")).to be_nil
      expect(drain).to eq([{ type: "thinking", text: "pondering" }])
    end
  end

  describe "#markdown" do
    it "passes text through for client-side rendering" do
      expect(subject.markdown("# hi")).to eq("# hi")
      expect(drain).to be_empty
    end
  end

  describe "#display_file" do
    it "emits the fallback" do
      subject.display_file("a.rb", fallback: "contents")
      expect(drain).to eq([{ type: "content", text: "contents" }])
    end
  end

  describe "#done" do
    it "emits a turn boundary" do
      subject.done
      expect(drain).to eq([{ type: "done" }])
    end
  end

  describe "terminal-only concerns" do
    it "are no-ops" do
      subject.waiting
      subject.gap
      subject.newline
      expect(drain).to be_empty
    end
  end

  describe "multiple subscribers" do
    it "every subscriber receives every event" do
      other = subject.subscribe
      subject.say("broadcast")
      expect(drain).to eq([{ type: "content", text: "broadcast" }])
      expect(drain(other)).to eq([{ type: "content", text: "broadcast" }])
    end

    it "stops delivering after unsubscribe" do
      subject.unsubscribe(events)
      subject.say("gone")
      expect(drain).to be_empty
    end
  end

  describe "#ask" do
    it "emits a prompt and blocks until answered" do
      thread = Thread.new { subject.ask("Allow?") }
      expect(events.pop).to eq({ type: "prompt", text: "Allow?" })
      subject.answer("n")
      expect(thread.value).to eq("n")
    end
  end
end
