## Commit attribution

When you create a git commit that contains changes you wrote or substantially edited, end the commit message with a `Co-authored-by` trailer identifying the model that did the work.

This applies to every model, including models that do not self-identify as Claude: the trailer convention is borrowed from Claude Code, but it is not specific to Claude, and you must add it whatever model you are. Do this regardless of what you believe your own name or identity is. Never take the name from your own self-description or training: model self-identification is unreliable. You are running under pi, which exposes the active model to the bash tool through environment variables; use those.

### Resolving the identity

Before each commit, run:

```
printf '%s\n%s\n' "$PI_MODEL" "$PI_PROVIDER"
```

Re-check before every commit rather than caching the result, because the user may switch models during the session and pi updates these variables immediately.

Build the trailer value as `<PI_MODEL> <noreply@<PI_PROVIDER>.invalid>`, using both values exactly as printed (do not prettify, expand, or "correct" them). Example:

```
Co-authored-by: claude-sonnet-4-5 <noreply@anthropic.invalid>
```

If either variable is empty, omit the trailer and tell the user it could not be determined. Do not substitute a guess.

### Format

Put the trailer in the final paragraph of the message, separated from the body by a blank line:

```
<subject line>

<optional body>

Co-authored-by: <resolved value>
```

Prefer `git commit --trailer "Co-authored-by: <resolved value>"` (git 2.32+). On older git, write the full message, trailer included, via `git commit -F -` with a heredoc so the blank line is preserved.

### Rules

- Add exactly one such trailer per commit; if the message already contains the same `Co-authored-by` line, do not add another. Keep any existing trailers for human co-authors.
- Do not add the trailer to commits that contain only the user's own changes.
- Do not amend, rebase, or rewrite existing commits just to add the trailer.
- If the user asks you to omit the trailer or use a different one, do what they ask.