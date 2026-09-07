# frozen_string_literal: true

RSpec.describe Elelem::Agent do
  def client_calling(name, arguments)
    Class.new do
      def initialize
        @calls = 0
      end

      define_method(:fetch) do |_messages, _tools, &block|
        @calls += 1
        block.call(type: "saying", text: "ok")
        block.call(type: "doing", id: "1", name: name, arguments: arguments) if @calls == 1
      end
    end.new
  end

  describe "#turn" do
    it "resolves an alias to its canonical name before rendering" do
      toolbox = Elelem::Toolbox.new
      toolbox.add("read", description: "Read", aliases: ["open"]) { |_a| { ok: true } }

      rendered = nil
      output = Elelem::NullOutput.new
      output.define_singleton_method(:doing) { |name, _args, **| rendered = name }

      agent = described_class.new(client_calling("open", {}), toolbox: toolbox, output: output)
      agent.turn("go")

      expect(rendered).to eq("read")
    end

    it "does not raise when dispatching a tool call against the real NullOutput default" do
      toolbox = Elelem::Toolbox.new
      toolbox.add("noop", description: "noop") { |_a| {} }

      agent = described_class.new(client_calling("noop", {}), toolbox: toolbox)

      expect { agent.turn("go") }.not_to raise_error
    end
  end
end
