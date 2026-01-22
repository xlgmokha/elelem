# frozen_string_literal: true

Elelem::Plugins.register(:eval) do |toolbox|
  toolbox.add("eval",
    description: "Evaluate Ruby code. Use `toolbox.add(name, description:, params:, required:) { |args| ... }` to register new tools.",
    params: { ruby: { type: "string" } },
    required: ["ruby"]
  ) do |args|
    { result: binding.eval(args["ruby"]) }
  end
end
