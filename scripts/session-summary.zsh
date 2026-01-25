#!/usr/bin/env zsh
#
# session-summary.zsh - Generate running session summary on Stop hook
#
# Uses Haiku to generate a brief session summary, stores per-session.
# View with tmux keybind: prefix + S (requires tmux config addition)
#

# Summary storage directory
SUMMARY_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/claude-sessions"
mkdir -p "$SUMMARY_DIR"

# Use session ID for filename, fall back to timestamp
SESSION_ID="${CLAUDE_SESSION_ID:-$(date +%Y%m%d-%H%M%S)}"
SUMMARY_FILE="$SUMMARY_DIR/${SESSION_ID}.md"
LOG_FILE="$SUMMARY_DIR/summary.log"
DEBUG_OUTPUT="$SUMMARY_DIR/debug-output.txt"

# Background the API call to avoid blocking
{
  echo "$(date -Iseconds) session=${SESSION_ID} status=started" >> "$LOG_FILE"

  output=$(
    claude --continue \
      --model haiku \
      --output-format=json \
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

  # Debug: save raw output
  echo "$output" > "$DEBUG_OUTPUT"

  # Check for API errors
  if echo "$output" | jq -e '.is_error == true' >/dev/null 2>&1; then
    error_msg=$(echo "$output" | jq -r '.error // "unknown"' 2>/dev/null)
    echo "$(date -Iseconds) session=${SESSION_ID} status=error message=\"${error_msg}\"" >> "$LOG_FILE"
    exit 0
  fi

  # Extract summary text from json output (result field contains the response)
  summary=$(echo "$output" | jq -r '.result // empty' 2>/dev/null)

  # Log cost
  cost=$(echo "$output" | jq -r '.total_cost_usd // 0' 2>/dev/null)
  input_tokens=$(echo "$output" | jq -r '.usage.input_tokens // 0' 2>/dev/null)
  output_tokens=$(echo "$output" | jq -r '.usage.output_tokens // 0' 2>/dev/null)
  if [[ "$cost" != "0" && "$cost" != "null" ]]; then
    echo "$(date -Iseconds) session=${SESSION_ID} cost=\$${cost} input=${input_tokens} output=${output_tokens}" >> "$LOG_FILE"
  fi

  # Write summary to per-session file
  if [[ -n $summary ]]; then
    cat > "$SUMMARY_FILE" << EOF
<!-- Session: ${SESSION_ID} | Updated: $(date -Iseconds) -->

${summary}
EOF
    # Update latest symlink
    ln -sf "${SESSION_ID}.md" "$SUMMARY_DIR/latest.md"
    echo "$(date -Iseconds) session=${SESSION_ID} status=success file=${SUMMARY_FILE}" >> "$LOG_FILE"
  else
    echo "$(date -Iseconds) session=${SESSION_ID} status=empty_summary" >> "$LOG_FILE"
  fi
} &!
