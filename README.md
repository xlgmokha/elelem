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

### Examples

```bash
# Chat with default model
elelem chat

# Chat with specific model and host
elelem chat --model llama2 --host remote-host:11434
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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
