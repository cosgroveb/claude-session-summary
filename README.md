# Claude Session Summary

A Claude Code plugin that generates running session summaries on every stop, viewable via tmux popup.

## How It Works

On every Claude Code stop event, this plugin:

1. Calls Claude Haiku with `--continue` to summarize the current session
2. Writes the summary to `~/.local/share/claude-sessions/<session_id>.md`
3. Updates `latest.md` symlink to point to the most recent summary
4. Logs cost/usage to `~/.local/share/claude-sessions/summary.log`

Each session gets its own file, preserving history across sessions.

## Installation

```bash
claude plugins add cosgroveb/claude-session-summary
```

## Viewing Summaries

Add this to your `~/.tmux.conf` to view with `prefix + S`:

```tmux
bind-key S display-popup -w 80% -h 60% -E "glow -p ~/.local/share/claude-sessions/latest.md 2>/dev/null || { echo 'No session summary yet.'; read; }"
```

Requires [glow](https://github.com/charmbracelet/glow) for markdown rendering. Install with:

```bash
brew install glow  # macOS
apt install glow   # Debian/Ubuntu
```

Or use `cat` instead of `glow` for plain text.

## Output Format

```markdown
## <2-4 word title>

**Objective:** <1 sentence>

**Completed:**
- <bullet points>

**Artifacts:** <commits, files, or "None">
```

## Cost

Each summary costs ~$0.001-0.003 using Haiku, depending on session length.

View cost history:

```bash
cat ~/.local/share/claude-sessions/summary.log
```

## Related

- [claude-tmux-namer](https://github.com/cosgroveb/claude-tmux-namer) - Names tmux windows based on session context

## License

MIT
