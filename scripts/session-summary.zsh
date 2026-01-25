#!/usr/bin/env zsh
#
# session-summary.zsh - Generate running session summary on Stop hook
#
# Uses Haiku to generate a brief session summary, stores in conventional location.
# View with tmux keybind: prefix + S (requires tmux config addition)
#

# Exit silently if not in tmux
[[ -z $TMUX ]] && exit 0

# Summary storage directory
SUMMARY_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/claude-sessions"
mkdir -p "$SUMMARY_DIR"

SUMMARY_FILE="$SUMMARY_DIR/current.md"
LOG_FILE="$SUMMARY_DIR/summary.log"

# Background the API call to avoid blocking
{
  output=$(
    claude --continue \
      --model haiku \
      --output-format=stream-json \
      --verbose \
      --print \
      --settings '{"disableAllHooks": true}' \
      -p 'Generate a brief session summary in this exact format:

## <2-4 word title>

**Objective:** <1 sentence>

**Completed:**
- <bullet points of completed work>

**Artifacts:** <commits, files changed, or "None">

Keep it under 150 words. Output ONLY the markdown, nothing else.' \
      2>&1
  )

  # Check for API errors
  if echo "$output" | grep -q '"type":"error"'; then
    error_msg=$(echo "$output" | grep '"type":"error"' | jq -r '.error.message // "unknown"' 2>/dev/null | head -1)
    echo "$(date -Iseconds) error=\"API error\" message=\"${error_msg}\"" >> "$LOG_FILE"
    exit 0
  fi

  # Extract the summary from assistant text messages
  summary=$(echo "$output" | grep '^{' | jq -rs '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text] | add // empty')

  # Log cost
  result_line=$(echo "$output" | grep '"type":"result"' | head -1)
  if [[ -n $result_line ]]; then
    cost=$(echo "$result_line" | jq -r '.total_cost_usd // 0')
    input_tokens=$(echo "$result_line" | jq -r '.usage.input_tokens // 0')
    output_tokens=$(echo "$result_line" | jq -r '.usage.output_tokens // 0')
    echo "$(date -Iseconds) cost=\$${cost} input=${input_tokens} output=${output_tokens}" >> "$LOG_FILE"
  fi

  # Write summary to file (overwrite - always current session)
  if [[ -n $summary ]]; then
    cat > "$SUMMARY_FILE" << EOF
<!-- Updated: $(date -Iseconds) -->

${summary}
EOF
  fi
} &!
