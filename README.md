# claude-session-summary

[![Validate Plugin](https://github.com/cosgroveb/claude-session-summary/actions/workflows/validate.yml/badge.svg)](https://github.com/cosgroveb/claude-session-summary/actions/workflows/validate.yml)

A Claude Code plugin that automatically generates session summaries whenever Claude Code stops.

## How it works

On every Claude Code stop event, a Haiku agent reads the conversation context via `--continue` and generates a structured summary with a title, objective, completed items, and artifacts. Summaries are stored per-project under `~/.local/share/claude-sessions/`.

- **Asynchronous**: Forks to background to survive the hook timeout
- **Context-aware**: Has full conversation history via `--continue`
- **Per-project**: Organizes summaries by project directory

## Installation

Using Claude Code slash commands:

```
/plugin marketplace add git@github.com:cosgroveb/claude-session-summary.git
/plugin install claude-session-summary@claude-session-summary
```

Or clone and install manually:

```bash
git clone git@github.com:cosgroveb/claude-session-summary.git
cd claude-session-summary
make install
```

## Uninstallation

```
/plugin uninstall claude-session-summary
/plugin marketplace remove claude-session-summary
```

Or manually:

```bash
cd claude-session-summary
make uninstall
```

## Requirements

- Claude Code CLI
- tmux (for popup viewing)
- [glow](https://github.com/charmbracelet/glow) (optional, for markdown rendering)

## Viewing Summaries

Add to `~/.tmux.conf` for `prefix + S`:

```tmux
bind-key S display-popup -w 80% -h 60% -E "glow -p ~/.local/share/claude-sessions/latest.md 2>/dev/null || cat ~/.local/share/claude-sessions/latest.md 2>/dev/null || { echo 'No session summary yet.'; read; }"
```

## Output Format

```markdown
## <2-4 word title>

**Objective:** <1 sentence>

**Completed:**
- <bullet points>

**Artifacts:** <commits, files, or "None">
```

## FAQ

### How much does this cost?

Each summary uses Claude Haiku, the cheapest Claude model. Costs depend on whether Claude Code's context is cached:

| Scenario | Cost | When it happens |
|----------|------|-----------------|
| Cached | ~$0.001-0.003 | Most calls—when you're actively working |
| Not cached | ~$0.03-0.05 | First call in a session, or after ~5 min idle |

**Why the difference?** Claude Code sends ~30K tokens of system context with each API call. The API caches this context for ~5 minutes. Cached reads cost 1/10th as much. Since you're typically making multiple Claude requests while working, most summary calls hit the cache.

**Typical monthly cost:**
- Light use: pennies
- Heavy use: a few dollars

### Can I monitor costs?

Costs are logged to `~/.local/share/claude-sessions/<project>/summary.log`:

```
2026-01-26T12:00:00+00:00 session=abc123 status=success cost=$0.003 input_tokens=100 output_tokens=50
```

## Related

- [claude-tmux-namer](https://github.com/cosgroveb/claude-tmux-namer) - Names tmux windows based on session context

## License

MIT
