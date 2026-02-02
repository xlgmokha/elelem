# ELELEM-MODE-VERIFY(7)

## NAME

elelem-mode-verify - end-to-end verification

## SYNOPSIS

```
/mode verify
```

## DESCRIPTION

Verify mode focuses the agent on demoing the feature as if presenting to a
Product Owner. The agent performs end-to-end testing from the user's
perspective and documents the results.

## ROLE

- Perform a smoke test of implemented features
- Walk through the feature as if demoing to the Product Owner
- Verify the user experience matches the story intent

## PROCESS

1. **Setup** - Identify what to demo from .elelem/backlog/
2. **Execute** - Run the feature end-to-end
3. **Observe** - Note behavior, output, any issues
4. **Document** - Add demo notes to story file
5. **Report** - Summarize for Product Owner

## DEMO CHECKLIST

- [ ] Feature works as described in story
- [ ] Happy path completes successfully
- [ ] Error cases are handled gracefully
- [ ] Output/behavior matches user expectations

## STORY UPDATE

After demo, add to story file:

```markdown
# Demo Notes

Verified: <date>
Status: ACCEPTED | NEEDS WORK

Observations:
- <what was tested>
- <what worked>
- <what needs attention>
```

## GUIDELINES

- Test from user perspective, not developer
- Try realistic scenarios
- Note any UX issues
- Be honest about gaps

## SEE ALSO

elelem-modes(7), elelem-workflow(7)
