# frozen_string_literal: true

RSpec.describe Elelem::SystemPrompt do
  subject(:prompt) { described_class.new }

  before { described_class.reload! }

  describe ".available_modes" do
    subject(:modes) { described_class.available_modes }

    it { is_expected.to include("default", "plan") }
    it { is_expected.to eq(modes.sort) }
  end

  describe ".get" do
    it { expect(described_class.get("default")).to include("Terminal coding agent") }
    it { expect(described_class.get("plan")).to include("Scrum Master") }
    it { expect(described_class.get("nonexistent")).to eq(described_class.get("default")) }
  end

  it { expect(prompt.template).to include("Terminal coding agent") }
  it { expect(prompt.mode).to eq("default") }

  describe "#switch" do
    before { prompt.switch("plan") }

    it { expect(prompt.mode).to eq("plan") }
    it { expect(prompt.template).to include("Scrum Master") }
  end

  describe "override behavior" do
    let(:tmpdir) { Dir.mktmpdir }

    around do |example|
      original_dir = Dir.pwd
      Dir.chdir(tmpdir)
      dir = ".elelem/prompts"
      FileUtils.mkdir_p(dir)
      File.write("#{dir}/custom.erb", "Custom template")
      described_class.reload!
      example.run
      Dir.chdir(original_dir)
      FileUtils.rm_rf(tmpdir)
      described_class.reload!
    end

    it { expect(described_class.available_modes).to include("custom") }
    it { expect(described_class.get("custom")).to eq("Custom template") }

    it "project templates override built-in" do
      dir = ".elelem/prompts"
      File.write("#{dir}/default.erb", "Overridden default")
      described_class.reload!

      expect(described_class.get("default")).to eq("Overridden default")
    end
  end
end
