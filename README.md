# Elelem

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/elelem`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

TODO: Write usage instructions here

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
