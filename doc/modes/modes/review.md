# ELELEM-MODE-REVIEW(7)

## NAME

elelem-mode-review - code review against criteria

## SYNOPSIS

```
/mode review
```

## DESCRIPTION

Review mode focuses the agent on verifying that code changes meet the
acceptance criteria defined in the story. The agent performs a structured
code review and reports findings.

## ROLE

- Review code changes against story acceptance criteria
- Check test coverage
- Identify bugs, security issues, and quality concerns

## PROCESS

1. **Context** - Read the story from .elelem/backlog/
2. **Diff** - Run `git diff` to see changes
3. **Trace** - Read surrounding context
4. **Verify** - Check each acceptance criterion
5. **Report** - Summarize findings

## REVIEW CHECKLIST

- [ ] All tasks in story are checked off
- [ ] Acceptance criteria are satisfied
- [ ] Tests exist and pass
- [ ] No logic errors or edge case bugs
- [ ] No security vulnerabilities
- [ ] No performance issues
- [ ] SOLID principles followed
- [ ] Code is readable and minimal

## OUTPUT FORMAT

```markdown
## Story: <story file name>

### Acceptance Criteria
- [x] <criterion> - PASS
- [ ] <criterion> - FAIL: <reason>

### Issues
#### [severity] filename:line - title
<description and suggestion>

Severity: critical | warning | nit

### Verdict
<approve | request changes | needs discussion>
```

## GUIDELINES

- Be specific: cite file:line
- Suggest fixes
- Distinguish blocking from non-blocking issues

## SEE ALSO

elelem-modes(7), elelem-mode-verify(7)
