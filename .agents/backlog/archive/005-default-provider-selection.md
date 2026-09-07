As a `new user`, I `want elelem to use local inference by default`, so that `I can start using it immediately without any configuration`.

# SYNOPSIS

Make the local provider the default when no configuration exists.

# DESCRIPTION

Update elelem's provider selection logic so that:

1. **First-run experience**:
   - When no `.elelem.yml` exists and no environment variables are set
   - Automatically select the local provider
   - Trigger model download if needed (Story 003)
   - Start the normal prompt interface - no wizard or extra questions

2. **Provider priority** (when no explicit config):
   1. Local provider (new default)
   2. Ollama (if running and accessible)
   3. OpenAI (if OPENAI_API_KEY set)
   4. Claude (if ANTHROPIC_API_KEY set)

3. **Explicit configuration**:
   - Users can still configure any provider in `.elelem.yml`
   - Explicit config always takes precedence
   - Document how to switch providers

4. **Seamless transition**:
   - Existing users with configuration are not affected
   - Only new users (no config) get the new default behavior

# SEE ALSO

* [ ] Story 004 (local provider implementation)
* [ ] lib/elelem/agent.rb (provider selection logic)
* [ ] Configuration loading code

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] New user with no config starts elelem and can chat immediately
* [ ] Local provider is used by default (not Ollama or cloud providers)
* [ ] Model downloads automatically on first run if not present
* [ ] Existing users with `.elelem.yml` are not affected
* [ ] Users with API keys in environment can still use cloud providers
* [ ] Clear documentation on how to configure different providers
