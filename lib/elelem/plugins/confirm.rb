# frozen_string_literal: true

Elelem::Plugins.register(:confirm) do |toolbox|
  toolbox.before("execute") do |args|
    next unless $stdin.tty?

    cmd = args["command"]
    $stdout.print "  Allow? [Y/n] > "
    answer = $stdin.gets&.strip&.downcase
    raise "User denied permission to execute: #{cmd}" if answer == "n"
  end
end
