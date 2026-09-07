# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe Elelem::Plugins do
  subject(:plugins) { described_class.new }

  let(:tmp_dir) { Dir.mktmpdir }
  let(:plugin_dir) { File.join(tmp_dir, "plugins") }

  before do
    FileUtils.mkdir_p(plugin_dir)
    stub_const("Elelem::Plugins::LOAD_PATHS", [plugin_dir].freeze)
  end

  after { FileUtils.remove_entry(tmp_dir) }

  it "loads .rb files from the configured paths" do
    File.write(File.join(plugin_dir, "probe.rb"), "$plugins_spec_loaded = true")

    plugins.load!

    expect($plugins_spec_loaded).to eq(true)
  ensure
    $plugins_spec_loaded = nil
  end

  it "only loads once unless forced" do
    File.write(File.join(plugin_dir, "counter.rb"), "$plugins_spec_count = ($plugins_spec_count || 0) + 1")

    plugins.load!
    plugins.load!

    expect($plugins_spec_count).to eq(1)
  ensure
    $plugins_spec_count = nil
  end

  it "reloads when forced" do
    File.write(File.join(plugin_dir, "counter.rb"), "$plugins_spec_count = ($plugins_spec_count || 0) + 1")

    plugins.load!
    plugins.load!(force: true)

    expect($plugins_spec_count).to eq(2)
  ensure
    $plugins_spec_count = nil
  end
end
