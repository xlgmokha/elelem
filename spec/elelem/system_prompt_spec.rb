# frozen_string_literal: true

RSpec.describe Elelem::SystemPrompt do
  before { described_class.reload! }

  describe ".available_modes" do
    it "returns sorted list of template names" do
      expect(described_class.available_modes).to include("default", "plan")
    end

    it "returns names in alphabetical order" do
      modes = described_class.available_modes
      expect(modes).to eq(modes.sort)
    end
  end

  describe ".get" do
    it "returns template content for known name" do
      template = described_class.get("default")
      expect(template).to include("Terminal coding agent")
    end

    it "returns plan template" do
      template = described_class.get("plan")
      expect(template).to include("Scrum Master")
    end

    it "falls back to default for unknown name" do
      template = described_class.get("nonexistent")
      expect(template).to eq(described_class.get("default"))
    end
  end

  describe "#switch" do
    it "changes the template" do
      prompt = described_class.new
      expect(prompt.template).to include("Terminal coding agent")

      prompt.switch("plan")
      expect(prompt.template).to include("Scrum Master")
    end

    it "updates the mode name" do
      prompt = described_class.new
      expect(prompt.mode).to eq("default")

      prompt.switch("plan")
      expect(prompt.mode).to eq("plan")
    end
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

    it "loads project-level templates" do
      expect(described_class.available_modes).to include("custom")
      expect(described_class.get("custom")).to eq("Custom template")
    end

    it "project templates override built-in" do
      dir = ".elelem/prompts"
      File.write("#{dir}/default.erb", "Overridden default")
      described_class.reload!

      expect(described_class.get("default")).to eq("Overridden default")
    end
  end
end
