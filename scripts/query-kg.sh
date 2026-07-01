#!/usr/bin/env bash
# query-kg.sh — Query the knowledge graph for entities matching a search term.
# Uses `graphify query` if graphify is on PATH; falls back to jq/grep on graph.json.
# Usage: bash scripts/query-kg.sh "<query>"
set -euo pipefail

QUERY="${1:-}"
GRAPH="graphify-out/graph.json"
REPORT="graphify-out/GRAPH_REPORT.md"

if [ -z "$QUERY" ]; then
  echo "[kg] ERROR: No query provided. Usage: bash scripts/query-kg.sh \"<query>\"" >&2
  exit 1
fi

if [ ! -f "$GRAPH" ]; then
  echo "[kg] ERROR: graphify-out/graph.json not found. Run scripts/setup-kg.sh first." >&2
  exit 1
fi

echo "[kg] Querying for: $QUERY"
echo "---"

if command -v graphify >/dev/null 2>&1; then
  # Use official graphify query command
  graphify query "$QUERY"
elif command -v jq >/dev/null 2>&1; then
  # Fallback: parse graph.json directly with jq
  jq --arg q "$QUERY" '
    .nodes[]
    | select(
        (.id    // "" | ascii_downcase | contains($q | ascii_downcase)) or
        (.label // "" | ascii_downcase | contains($q | ascii_downcase)) or
        (.type  // "" | ascii_downcase | contains($q | ascii_downcase)) or
        (.file  // "" | ascii_downcase | contains($q | ascii_downcase))
      )
    | {id, type, label, file}
  ' "$GRAPH" 2>/dev/null | head -60 || echo "[kg] No matching nodes."
else
  # Last resort: grep
  grep -i "$QUERY" "$GRAPH" | head -30 || echo "[kg] No matches."
fi

# Surface GRAPH_REPORT.md summary for broader context
if [ -f "$REPORT" ]; then
  echo ""
  echo "[kg] GRAPH_REPORT.md summary:"
  echo "---"
  head -50 "$REPORT"
fi
