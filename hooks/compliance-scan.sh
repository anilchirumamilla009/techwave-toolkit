#!/usr/bin/env bash
# techwave-toolkit compliance-scan.sh
# Called by Claude Code after every Write/Edit tool use.
# Exits 0 (silent) if file is clean.
# Emits a one-line warning if a credential or PII-in-log pattern is detected.

set -euo pipefail

# Read the file path from hook environment (Claude passes tool input via stdin as JSON)
FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
  FILE_PATH=$(jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
fi

# If jq is unavailable or produced no path, fall back to reading from env
if [ -z "$FILE_PATH" ]; then
  FILE_PATH="${CLAUDE_TOOL_FILE_PATH:-}"
fi

# Exit cleanly if no file path was provided or file doesn't exist
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Skip binary files (non-text) to avoid false positives and errors
if ! file "$FILE_PATH" | grep -q "text"; then
  exit 0
fi

# Skip very large files (> 500KB) to stay under the 5s timeout
FILE_SIZE=$(wc -c < "$FILE_PATH" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -gt 512000 ]; then
  exit 0
fi

WARNINGS=""

# Pattern 1: Hardcoded credential in assignment
# Matches: password = "...", api_key: "...", secret = '...' (4+ chars after = or :)
if grep -iEq '(password|passwd|api_key|api_secret|secret_key|access_token|auth_token|private_key)\s*[:=]\s*["\x27][^"\x27]{4,}["\x27]' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}[techwave-toolkit] WARNING: Possible hardcoded credential detected in ${FILE_PATH}. Use environment variables or a secrets manager instead.\n"
fi

# Pattern 2: PII values passed directly to logging calls
# Matches: console.log(...email...), logger.info(...ssn...), print(...phone...)
if grep -iEq '(console\.(log|warn|error|debug|info)|logger\.(info|debug|warn|error|critical)|print\s*\(|logging\.(info|debug|warning|error))\s*\(.*\b(ssn|social.security|credit.card|password|phone.number|date.of.birth|patient.id)\b' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}[techwave-toolkit] WARNING: Possible PII in log statement detected in ${FILE_PATH}. Remove PII from logs or use pseudonymization.\n"
fi

# Pattern 3: AWS/GCP/Azure keys embedded in code
# AWS access key format: AKIA... (20 uppercase alphanumeric characters)
if grep -Eq '\bAKIA[A-Z0-9]{16}\b' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}[techwave-toolkit] WARNING: Possible AWS Access Key ID detected in ${FILE_PATH}. Revoke and rotate this key immediately.\n"
fi

# Emit warnings if any were found
if [ -n "$WARNINGS" ]; then
  printf "%b" "$WARNINGS" >&2
  exit 1
fi

exit 0
