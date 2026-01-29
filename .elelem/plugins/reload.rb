# frozen_string_literal: true

Elelem::Plugins.register(:reload) do |agent|
  agent.commands.register("reload", description: "Reload plugins and source") do
    lib_dir = File.join(Dir.pwd, "lib")
    original_verbose, $VERBOSE = $VERBOSE, nil
    Dir["#{lib_dir}/**/*.rb"].sort.each { |f| load(f) }
    $VERBOSE = original_verbose
    agent.toolbox = Elelem::Toolbox.new
    agent.commands = Elelem::Commands.new
    Elelem::Plugins.reload!(agent)
  end
end
