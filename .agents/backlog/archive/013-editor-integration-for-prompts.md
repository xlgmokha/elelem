# Editor Integration for Prompts

As a **power user**, I want to open my `$EDITOR` from the prompt to compose long messages, so that I have a full editing environment for complex prompts.

## SYNOPSIS

Press `CTRL+x CTRL+e` at the prompt to open `$EDITOR`, compose text, and return to the prompt for review before sending.

## DESCRIPTION

When composing long or complex prompts, the terminal input line is limiting. Users need the ability to:
- Write multi-line text comfortably
- Paste content from other sources
- Use familiar editor keybindings (vim, emacs, etc.)
- Review and edit before sending

### Keybinding

`CTRL+x CTRL+e` - Standard Bash/Zsh binding for `edit-and-execute-command`

This is the most intuitive choice for Linux/Bash/Vim/Tmux users as it matches their existing muscle memory.

### Flow

```
> partial text█              # User types some text
                             # User presses CTRL+x CTRL+e
                             # Editor opens with "partial text" pre-populated
                             # User edits, saves, quits
> partial text               # Text appears at prompt
  plus more content          # (multi-line if applicable)
  from the editor█           # Cursor at end, ready to review
                             # User presses Enter to send
```

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| Empty file saved | Return to prompt, no input |
| Editor exits non-zero | Return to prompt, preserve original text |
| `$EDITOR` not set | Fall back to `$VISUAL`, then `vi` |
| Multi-line text | Display all lines, submit as single message |

## SEE ALSO

* [ ] lib/elelem/terminal.rb - `ask` method, Reline configuration
* [ ] Reline documentation for custom key bindings
* [ ] Bash `edit-and-execute-command` (CTRL+x CTRL+e)

## Tasks

* [ ] TBD (filled in design mode)

## Acceptance Criteria

* [ ] `CTRL+x CTRL+e` opens `$EDITOR` (or `$VISUAL`, or `vi`)
* [ ] Editor pre-populates with any text already typed at the prompt
* [ ] After saving and quitting, text appears at the prompt for review
* [ ] User must press Enter to send (no auto-submit)
* [ ] Empty file returns to prompt with no input (cancel)
* [ ] Non-zero editor exit preserves original text
* [ ] Temp file is created in appropriate location and cleaned up after
* [ ] Multi-line text from editor displays correctly at prompt
* [ ] Works with common editors: vim, nvim, nano, emacs

## Implementation Notes

```ruby
# In Terminal, bind CTRL+x CTRL+e
Reline::LineEditor.bind_key("\C-x\C-e") do |line_editor|
  # 1. Get current line content
  current_text = line_editor.line

  # 2. Create temp file with content
  require "tempfile"
  file = Tempfile.new(["elelem-prompt-", ".md"])
  file.write(current_text)
  file.close

  # 3. Open editor
  editor = ENV["VISUAL"] || ENV["EDITOR"] || "vi"
  system("#{editor} #{file.path}")

  # 4. Read result
  if $?.success?
    new_text = File.read(file.path).strip
    line_editor.replace_line(new_text) unless new_text.empty?
  end

  # 5. Cleanup
  file.unlink
end
```

### Multi-line Display

Reline supports multi-line input. The edited text should be inserted and displayed across multiple lines if it contains newlines.
