# frozen_string_literal: true

Elelem::Plugins.register(:confirm) do |agent|
  agent.toolbox.before("execute") do |args|
    next unless $stdin.tty?

    cmd = args["command"]
    answer = agent.terminal.ask("  Allow? [Y/n] > ")&.downcase
    raise "User denied permission to execute: #{cmd}" if answer == "n"
  end
end
