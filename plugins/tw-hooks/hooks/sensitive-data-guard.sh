#!/usr/bin/env bash
# techwave-toolkit sensitive-data-guard.sh
# PreToolUse hook: prevents sensitive data from being exposed by blocking
#  (a) Read of secret-bearing files (they would land in the model context
#      and can leak into chat, commits, or generated code), and
#  (b) Bash commands that print or ship those files (cat/curl/base64/...).
# Exit 0  = allow the tool call.
# Exit 2  = block the tool call; stderr is fed back to the model.

set -euo pipefail

STDIN_JSON="$(cat 2>/dev/null || true)"
[ -z "$STDIN_JSON" ] && exit 0

TOOL_NAME=""
FILE_PATH=""
COMMAND=""
if command -v jq >/dev/null 2>&1; then
  TOOL_NAME=$(printf '%s' "$STDIN_JSON" | jq -r '.tool_name // empty' 2>/dev/null || true)
  FILE_PATH=$(printf '%s' "$STDIN_JSON" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)
  COMMAND=$(printf '%s' "$STDIN_JSON" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  TOOL_NAME=$(printf '%s' "$STDIN_JSON" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 || true)
  FILE_PATH=$(printf '%s' "$STDIN_JSON" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 || true)
  COMMAND=$(printf '%s' "$STDIN_JSON" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"[,}].*/\1/p' | head -n 1 || true)
fi

# Sensitive-file pattern (ERE). Matches real secret stores; the corresponding
# templates (.env.example / .env.sample / .env.template) are explicitly allowed.
SENSITIVE_PAT='(^|/)\.env(\.[A-Za-z0-9_-]+)?$|\.pem$|\.key$|(^|/)id_(rsa|dsa|ecdsa|ed25519)[^/]*$|\.p12$|\.pfx$|\.keystore$|\.jks$|(^|/)credentials(\.json)?$|service-account[^/]*\.json$|(^|/)\.aws/credentials|(^|/)\.netrc$|\.tfstate(\.backup)?$|(^|/)secrets?\.(json|ya?ml|env|properties)$|(^|/)\.npmrc$|(^|/)\.pypirc$|(^|/)\.docker/config\.json$'
TEMPLATE_PAT='\.env\.(example|sample|template|dist)$'

is_sensitive() {
  printf '%s' "$1" | grep -Eq "$SENSITIVE_PAT" && ! printf '%s' "$1" | grep -Eq "$TEMPLATE_PAT"
}

case "$TOOL_NAME" in
  Read|read)
    if [ -n "$FILE_PATH" ] && is_sensitive "$FILE_PATH"; then
      {
        echo "[tw-hooks] BLOCKED: ${FILE_PATH} matches a sensitive-file pattern (secrets/credentials/keys)."
        echo "[tw-hooks] Do not load secret values into the conversation. Use the corresponding template (.env.example) or ask the user for the variable NAMES you need — never the values."
      } >&2
      exit 2
    fi
    ;;
  Bash|bash|PowerShell|powershell)
    if [ -n "$COMMAND" ]; then
      # Exposure verbs: anything that prints, copies out, encodes, or uploads file content.
      EXPOSE_PAT='\b(cat|head|tail|less|more|strings|xxd|hexdump|base64|curl|wget|nc|ncat|scp|rsync|ftp|mail|Get-Content|type)\b'
      # Sensitive path referenced inside the command (subset of SENSITIVE_PAT usable mid-string).
      CMD_SENSITIVE_PAT='\.env([^.A-Za-z0-9_-]|$)|\.pem\b|(^|[^A-Za-z0-9_])id_(rsa|dsa|ecdsa|ed25519)|\.p12\b|\.pfx\b|\.keystore\b|\.jks\b|\.aws/credentials|\.netrc\b|\.tfstate\b|secrets?\.(json|ya?ml|env|properties)\b|\.npmrc\b|\.pypirc\b|\.docker/config\.json'
      CMD_TEMPLATE_PAT='\.env\.(example|sample|template|dist)'
      if printf '%s' "$COMMAND" | grep -Eq "$EXPOSE_PAT" \
         && printf '%s' "$COMMAND" | grep -Eq "$CMD_SENSITIVE_PAT" \
         && ! printf '%s' "$COMMAND" | grep -Eq "$CMD_TEMPLATE_PAT"; then
        {
          echo "[tw-hooks] BLOCKED: this command reads or transmits a sensitive file (secrets/credentials/keys)."
          echo "[tw-hooks] Never print, encode, or upload secret files. Reference variable NAMES via the template (.env.example); leave values on the user's machine."
        } >&2
        exit 2
      fi
    fi
    ;;
esac

exit 0
