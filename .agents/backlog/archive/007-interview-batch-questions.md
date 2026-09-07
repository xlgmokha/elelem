As an `agent`, I `want to ask multiple questions at once`, so that `I can collect related information in a single interaction like a form`.

# SYNOPSIS

Allow the interview tool to accept an array of questions and return all answers together.

# DESCRIPTION

Building on the question types feature, this story adds the ability to send a batch of questions in a single interview call. This is useful when the agent needs to collect several related pieces of information and it would be tedious to ask them one at a time.

Example API:
```ruby
interview(questions: [
  { question: "What's your name?", type: "text" },
  { question: "Pick a color", type: "single", options: ["Red", "Green", "Blue"] },
  { question: "Select features", type: "multi", options: ["Auth", "API", "UI"] },
  { question: "Ready to proceed?", type: "yesno" }
])
```

The questions are presented sequentially, and all answers are collected before returning to the agent. The user can still respond with clarifying questions or unexpected input on any individual question.

The existing single-question API remains supported for backward compatibility.

# SEE ALSO

* [ ] .elelem/backlog/006-interview-question-types.md - Prerequisite: question types
* [ ] lib/elelem/terminal.rb - Terminal input/output handling

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Agent can pass `questions` array with multiple question objects
* [ ] Each question in the array can have its own type and options
* [ ] Questions are presented to user one at a time in order
* [ ] All answers are collected before returning to agent
* [ ] Response includes an array of answers matching the question order
* [ ] Single-question API (`question: "..."`) still works for backward compatibility
* [ ] If user provides unexpected input on one question, that input is captured and interview continues
* [ ] Agent receives enough context to understand which answer corresponds to which question
