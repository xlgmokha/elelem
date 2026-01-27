# frozen_string_literal: true

Elelem::Plugins.register(:gitlab) do |agent|
  agent.toolbox.after("gitlab_search") do |_args, result|
    IO.popen(["jq", "-C", "."], "r+") do |io|
      io.write(result.to_json)
      io.close_write
      agent.terminal.say(io.read)
    end
  end
end
