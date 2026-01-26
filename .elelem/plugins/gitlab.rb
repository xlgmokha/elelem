# frozen_string_literal: true

Elelem::Plugins.register(:gitlab) do |toolbox|
  toolbox.after("gitlab_search") do |_args, result|
    $stdout.puts result.inspect
  end
end
