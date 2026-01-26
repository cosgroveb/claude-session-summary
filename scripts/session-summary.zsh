#!/usr/bin/env zsh
#
# session-summary.zsh - Generate running session summary on Stop hook
#
# Uses Haiku to generate a brief session summary, stores per-project/session.
# View with tmux keybind: prefix + S
#

# Read hook input with timeout - don't let stdin block us
HOOK_INPUT=$(timeout 0.5 cat 2>/dev/null || echo '{}')

# Fork IMMEDIATELY to survive the hook timeout
# All processing happens in the background
{
  # Parse hook input - extract session_id and cwd
  SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null)
  PROJECT_DIR=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)

  # Fall back to timestamp if no session_id
  [[ -z $SESSION_ID ]] && SESSION_ID="unknown-$(date +%Y%m%d-%H%M%S)"

  # Derive project name from cwd (zsh native :t = basename)
  PROJECT_NAME="${PROJECT_DIR:t}"
  [[ -z $PROJECT_NAME ]] && PROJECT_NAME="default"

  # Summary storage: per-project directories
  BASE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/claude-sessions"
  PROJECT_SUMMARY_DIR="$BASE_DIR/$PROJECT_NAME"
  mkdir -p "$PROJECT_SUMMARY_DIR"

  SUMMARY_FILE="$PROJECT_SUMMARY_DIR/${SESSION_ID}.md"
  LOG_FILE="$BASE_DIR/summary.log"
  DEBUG_OUTPUT="$PROJECT_SUMMARY_DIR/debug-output.txt"

  echo "$(date -Iseconds) project=${PROJECT_NAME} session=${SESSION_ID} status=started" >> "$LOG_FILE"

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
    echo "$(date -Iseconds) project=${PROJECT_NAME} session=${SESSION_ID} status=error message=\"${error_msg}\"" >> "$LOG_FILE"
    exit 0
  fi

  # Extract summary text from json output (result field contains the response)
  # Use python with strict=False to handle unescaped control chars in strings
  summary=$(echo "$output" | python3 -c "import sys,json; d=json.loads(sys.stdin.read(),strict=False); print(d.get('result',''))" 2>/dev/null)

  # Log cost
  cost=$(echo "$output" | jq -r '.total_cost_usd // 0' 2>/dev/null)
  input_tokens=$(echo "$output" | jq -r '.usage.input_tokens // 0' 2>/dev/null)
  output_tokens=$(echo "$output" | jq -r '.usage.output_tokens // 0' 2>/dev/null)
  if [[ "$cost" != "0" && "$cost" != "null" ]]; then
    echo "$(date -Iseconds) project=${PROJECT_NAME} session=${SESSION_ID} cost=\$${cost} input=${input_tokens} output=${output_tokens}" >> "$LOG_FILE"
  fi

  # Write summary to per-session file
  if [[ -n $summary ]]; then
    cat > "$SUMMARY_FILE" << EOF
<!-- Session: ${SESSION_ID} | Project: ${PROJECT_NAME} | Updated: $(date -Iseconds) -->

${summary}
EOF
    # Update per-project latest symlink
    ln -sf "${SESSION_ID}.md" "$PROJECT_SUMMARY_DIR/latest.md"
    echo "$(date -Iseconds) project=${PROJECT_NAME} session=${SESSION_ID} status=success file=${SUMMARY_FILE}" >> "$LOG_FILE"
  else
    echo "$(date -Iseconds) project=${PROJECT_NAME} session=${SESSION_ID} status=empty_summary" >> "$LOG_FILE"
  fi
} &!

# Exit immediately - background job continues independently
exit 0
