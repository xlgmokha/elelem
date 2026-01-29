As an `agent`, I `want to ask questions with selectors and batch support`, so that `I can collect structured responses efficiently`.

# SYNOPSIS

Extend the interview tool to support text, single-select, and multi-select inputs with TUI navigation and batch question capability.

# DESCRIPTION

The interview tool currently only supports free-form text input. This story adds:

1. **Input modes**:
   - `text` - Free-form text input (current behavior, default)
   - `select` - Radio-button style single choice from options
   - `multi` - Checkbox style multiple choice from options

2. **TUI interaction** (when terminal supports it):
   - Arrow keys (up/down) to navigate between options
   - Space to toggle selection (multi-select)
   - Enter to confirm selection

3. **Numbered fallback** (for dumb terminals or piped input):
   - Display numbered list (e.g., "1. Red", "2. Green", "3. Blue")
   - User types number to select
   - Comma-separated numbers for multi-select (e.g., "1, 3")

4. **Batch questions**:
   - Accept array of questions in single call
   - Present sequentially, collect all answers before returning

# SEE ALSO

* [ ] lib/elelem/terminal.rb - Add `select` and `multi_select` methods
* [ ] lib/elelem/plugins/interview.rb - Add `options`, `multi`, and `questions` params

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Agent can provide `options` array to enable selector mode
* [ ] Agent can set `multi: true` to allow multiple selections
* [ ] Single-select with TUI: arrow keys navigate, enter confirms
* [ ] Multi-select with TUI: arrow keys navigate, space toggles, enter confirms
* [ ] Falls back to numbered list when terminal doesn't support TUI
* [ ] Free-form text input still works when no options provided
* [ ] Agent can pass `questions` array with multiple question objects
* [ ] Each question in batch can have its own options and multi setting
* [ ] Batch returns array of answers matching question order
* [ ] Single-question API remains backward compatible
* [ ] No new gem dependencies (uses io/console from stdlib)

# Implementation Notes

The following implementation plan is provided as guidance for the developer.

## Tool Schema

```json
{
  "question": { "type": "string", "description": "The question to ask" },
  "options": { "type": "array", "description": "List of options (enables selector)" },
  "multi": { "type": "boolean", "description": "Allow multiple selections" },
  "questions": { "type": "array", "description": "Batch of question objects" }
}
```

## Files to Modify

- `lib/elelem/terminal.rb` - Add `select` and `multi_select` methods
- `lib/elelem/plugins/interview.rb` - Add `options`, `multi`, and `questions` params

## Terminal API

```ruby
# Single select - returns selected option string
terminal.select(options) # => "option1"

# Multi select - returns array of selected options
terminal.multi_select(options) # => ["option1", "option3"]
```

## Reference Implementation

### Terminal#select (single choice)

```ruby
def select(options)
  return options.first if options.size == 1
  require "io/console"

  index = 0
  render_options = -> {
    options.each_with_index do |opt, i|
      prefix = i == index ? "> " : "  "
      $stdout.puts "#{prefix}#{opt}"
    end
  }

  render_options.call

  loop do
    key = read_key
    case key
    when :up then index = (index - 1) % options.size
    when :down then index = (index + 1) % options.size
    when :enter then break
    end
    $stdout.print "\e[#{options.size}A\e[J"
    render_options.call
  end

  options[index]
end

def read_key
  char = $stdin.getch
  return :enter if char == "\r" || char == "\n"
  return char unless char == "\e"

  return char unless $stdin.ready?
  seq = $stdin.getch
  return char unless seq == "["

  code = $stdin.getch
  case code
  when "A" then :up
  when "B" then :down
  else char
  end
end
```

### Terminal#multi_select (multiple choice)

```ruby
def multi_select(options)
  require "io/console"

  index = 0
  selected = Set.new

  render_options = -> {
    options.each_with_index do |opt, i|
      cursor = i == index ? ">" : " "
      check = selected.include?(i) ? "[x]" : "[ ]"
      $stdout.puts "#{cursor} #{check} #{opt}"
    end
  }

  render_options.call

  loop do
    key = read_key
    case key
    when :up then index = (index - 1) % options.size
    when :down then index = (index + 1) % options.size
    when :space then selected.include?(index) ? selected.delete(index) : selected.add(index)
    when :enter then break
    end
    $stdout.print "\e[#{options.size}A\e[J"
    render_options.call
  end

  options.values_at(*selected.to_a.sort)
end
```

### Updated Interview Plugin

```ruby
Elelem::Plugins.register(:interview) do |agent|
  agent.toolbox.add("interview",
    description: "Ask the user a question and wait for their response",
    params: {
      question: { type: "string", description: "The question to ask" },
      options: { type: "array", description: "List of options for selector" },
      multi: { type: "boolean", description: "Allow multiple selections" },
      questions: { type: "array", description: "Batch of question objects" }
    },
    required: ["question"]
  ) do |args|
    if args["questions"]&.any?
      # Batch mode
      answers = args["questions"].map do |q|
        agent.terminal.say(agent.terminal.markdown(q["question"]))
        ask_one(agent.terminal, q["options"], q["multi"])
      end
      { answers: answers }
    else
      # Single question mode
      agent.terminal.say(agent.terminal.markdown(args["question"]))
      answer = ask_one(agent.terminal, args["options"], args["multi"])
      { answer: answer }
    end
  end

  def ask_one(terminal, options, multi)
    if options&.any?
      multi ? terminal.multi_select(options) : terminal.select(options)
    else
      terminal.ask("> ")
    end
  end
end
```

## Verification

1. Run `./bin/run -p vertex`
2. Ask the LLM to use the interview tool with options
3. Test arrow key navigation
4. Test single select (Enter confirms)
5. Test multi select (Space toggles, Enter confirms)
6. Test free-form text still works when no options provided
7. Test batch questions with mixed types
8. Run `bin/test`
