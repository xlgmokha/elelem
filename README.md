# Elelem

Elelem is an interactive REPL (Read-Eval-Print Loop) for Ollama that provides a command-line chat interface for communicating with AI models. It features tool calling capabilities, streaming responses, and a clean state machine architecture.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add elelem
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install elelem
```

## Usage

Start an interactive chat session with an Ollama model:

```bash
elelem chat
```

### Options

- `--host`: Specify Ollama host (default: localhost:11434)
- `--model`: Specify Ollama model (default: gpt-oss, currently only tested with gpt-oss)  
- `--token`: Provide authentication token
- `--debug`: Enable debug logging

### Examples

```bash
# Chat with default model
elelem chat

# Chat with specific model and host
elelem chat --model llama2 --host remote-host:11434

# Enable debug mode
elelem chat --debug
```

### Features

- **Interactive REPL**: Clean command-line interface for chatting
- **Tool Execution**: Execute shell commands when requested by the AI
- **Streaming Responses**: Real-time streaming of AI responses
- **State Machine**: Robust state management for different interaction modes
- **Conversation History**: Maintains context across the session

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

REPL State Diagram

```
                      ┌─────────────────┐
                      │   START/INIT    │
                      └─────────┬───────┘
                                │
                                v
                      ┌─────────────────┐
                ┌────▶│ IDLE (Prompt)   │◄────┐
                │     │   Shows "> "    │     │
                │     └─────────┬───────┘     │
                │               │             │
                │               │ User input  │
                │               v             │
                │     ┌─────────────────┐     │
                │     │ PROCESSING      │     │
                │     │ INPUT           │     │
                │     └─────────┬───────┘     │
                │               │             │
                │               │ API call    │
                │               v             │
                │     ┌─────────────────┐     │
                │     │ STREAMING       │     │
                │ ┌──▶│ RESPONSE        │─────┤
                │ │   └─────────┬───────┘     │
                │ │             │             │ done=true
                │ │             │ Parse chunk │
                │ │             v             │
                │ │   ┌─────────────────┐     │
                │ │   │ MESSAGE TYPE    │     │
                │ │   │ ROUTING         │     │
                │ │   └─────┬─┬─┬───────┘     │
                │ │         │ │ │             │
       ┌────────┴─┴─────────┘ │ └─────────────┴──────────┐
       │                      │                          │
       v                      v                          v
  ┌─────────────┐    ┌─────────────┐          ┌─────────────┐
  │ THINKING    │    │ TOOL        │          │ CONTENT     │
  │ STATE       │    │ EXECUTION   │          │ OUTPUT      │
  │             │    │ STATE       │          │ STATE       │
  └─────────────┘    └─────┬───────┘          └─────────────┘
       │                   │                          │
       │                   │ done=false               │
       └───────────────────┼──────────────────────────┘
                           │
                           v
                 ┌─────────────────┐
                 │ CONTINUE        │
                 │ STREAMING       │
                 └─────────────────┘
                           │
                           └─────────────────┐
                                             │
       ┌─────────────────┐                   │
       │ ERROR STATE     │                   │
       │ (Exception)     │                   │
       └─────────────────┘                   │
                ▲                            │
                │ Invalid response           │
                └────────────────────────────┘

                      EXIT CONDITIONS:
                 ┌─────────────────────────┐
                 │ • User enters ""        │
                 │ • User enters "exit"    │
                 │ • EOF (Ctrl+D)          │
                 │ • nil input             │
                 └─────────────────────────┘
                            │
                            v
                 ┌─────────────────────────┐
                 │      TERMINATE          │
                 └─────────────────────────┘
```

Key Transitions:

1. IDLE → PROCESSING: User enters any non-empty, non-"exit" input
2. PROCESSING → STREAMING: API call initiated to Ollama
3. STREAMING → MESSAGE ROUTING: Each chunk received is parsed
4. MESSAGE ROUTING → States: Based on message content:
  - thinking → THINKING STATE
  - tool_calls → TOOL EXECUTION STATE
  - content → CONTENT OUTPUT STATE
  - Invalid format → ERROR STATE
5. All States → IDLE: When done=true from API response
6. TOOL EXECUTION → STREAMING: Sets done=false to continue conversation
7. Any State → TERMINATE: On exit conditions

The REPL operates as a continuous loop where the primary flow is IDLE → PROCESSING → STREAMING →
back to IDLE, with the streaming phase potentially cycling through multiple message types before
completion.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/xlgmokha/elelem.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
