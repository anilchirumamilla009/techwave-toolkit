#!/usr/bin/env bash
# techwave-toolkit compliance-scan.sh
# Called by Claude Code / Copilot CLI after every Write/Edit tool use.
# Exits 0 (silent) if file is clean.
# On a finding: emits warnings to stderr and exits 2 so the CLI feeds the
# warning back to the model (exit 1 would only show it to the user).

set -euo pipefail

# Hook input arrives as JSON on stdin. Read it once.
STDIN_JSON="$(cat 2>/dev/null || true)"

FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
  FILE_PATH=$(printf '%s' "$STDIN_JSON" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)
fi

# jq unavailable or produced nothing — extract "file_path":"..." with sed
if [ -z "$FILE_PATH" ] && [ -n "$STDIN_JSON" ]; then
  FILE_PATH=$(printf '%s' "$STDIN_JSON" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 || true)
fi

# Exit cleanly if no file path was provided or file doesn't exist
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Skip binary files (non-text) to avoid false positives and errors
if command -v file >/dev/null 2>&1 && ! file "$FILE_PATH" | grep -q "text"; then
  exit 0
fi

# Skip very large files (> 500KB) to stay under the 5s timeout
FILE_SIZE=$(wc -c < "$FILE_PATH" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -gt 512000 ]; then
  exit 0
fi

# Single-quote character for use inside ERE bracket expressions.
# (\x27 is NOT valid in POSIX ERE — a bracket expression treats backslash literally.)
SQ="'"

WARNINGS=""

# Pattern 1: Hardcoded credential in assignment
# Matches: password = "...", api_key: "...", secret = '...' (4+ chars after = or :)
CRED_PAT="(password|passwd|api_key|api_secret|secret_key|access_token|auth_token|private_key)[[:space:]]*[:=][[:space:]]*[\"$SQ][^\"$SQ]{4,}[\"$SQ]"
if grep -iEq "$CRED_PAT" "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}[tw-dev] WARNING: Possible hardcoded credential detected in ${FILE_PATH}. Use environment variables or a secrets manager instead.\n"
fi

# Pattern 2: PII values passed directly to logging calls
# Matches: console.log(...email...), logger.info(...ssn...), print(...phone...)
if grep -iEq '(console\.(log|warn|error|debug|info)|logger\.(info|debug|warn|error|critical)|print[[:space:]]*\(|logging\.(info|debug|warning|error))[[:space:]]*\(.*\b(ssn|social.security|credit.card|password|phone.number|date.of.birth|patient.id)\b' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}[tw-dev] WARNING: Possible PII in log statement detected in ${FILE_PATH}. Remove PII from logs or use pseudonymization.\n"
fi

# Pattern 3: AWS/GCP/Azure keys embedded in code
# AWS access key format: AKIA... (20 uppercase alphanumeric characters)
if grep -Eq '\bAKIA[A-Z0-9]{16}\b' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}[tw-dev] WARNING: Possible AWS Access Key ID detected in ${FILE_PATH}. Revoke and rotate this key immediately.\n"
fi

# Emit warnings if any were found — exit 2 feeds stderr back to the model
if [ -n "$WARNINGS" ]; then
  printf "%b" "$WARNINGS" >&2
  exit 2
fi

exit 0
