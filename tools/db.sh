#!/usr/bin/env bash
# Simple wrapper around the Flyway command line.
# Run from anywhere:  tools/db.sh <command> [args]
# Type "tools/db.sh help" for the list of commands.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'TXT'
Usage: tools/db.sh <command> [args]

  new <TICKET> <description>   Create a new versioned (V) file with a timestamp
  migrate <env>                Apply pending changes (env = personal | dev | ...)
  info <env>                   Show what has run and what is pending
  validate <env>               Check Git files against what already ran
  reset                        PERSONAL schema only: wipe it and rebuild from Git
  baseline <env>               ONE TIME, existing database: mark it as "already at V1"
  repair <env>                 Fix the history table after a failed run (see docs)

Password: set FLYWAY_PASSWORD before running. It is never stored in Git.
TXT
}

flyway_for() {
  local env="$1"; shift
  local conf="conf/env/${env}.conf"
  if [[ ! -f "$conf" ]]; then
    echo "ERROR: $conf not found." >&2
    [[ "$env" == "personal" ]] && echo "Copy conf/env/personal.conf.example to conf/env/personal.conf first." >&2
    exit 1
  fi
  echo ">> Environment: $env"
  flyway "-configFiles=conf/flyway.conf,${conf}" "$@"
}

cmd="${1:-help}"; shift || true
case "$cmd" in
  new)
    if [[ $# -lt 2 ]]; then echo "Usage: tools/db.sh new <TICKET> <description>" >&2; exit 1; fi
    ticket="$(echo "$1" | tr -cd '[:alnum:]')"; shift
    desc="$(echo "$*" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g')"
    file="db/migrations/versioned/V$(date +%Y%m%d%H%M%S)__${ticket}_${desc}.sql"
    cat > "$file" <<SQL
-- Ticket : $ticket
-- Purpose: $*
-- V file: runs ONCE. Never edit after merge - create a new V file instead.

SQL
    echo "Created $file"
    ;;
  migrate|info|validate)
    [[ $# -ge 1 ]] || { echo "Usage: tools/db.sh $cmd <env>" >&2; exit 1; }
    flyway_for "$1" "$cmd"
    ;;
  reset)
    echo "This WIPES your personal schema and rebuilds it from Git."
    flyway_for personal clean
    flyway_for personal migrate
    ;;
  baseline)
    [[ $# -ge 1 ]] || { echo "Usage: tools/db.sh baseline <env>" >&2; exit 1; }
    flyway_for "$1" baseline -baselineVersion=1 "-baselineDescription=initial schema"
    ;;
  repair)
    [[ $# -ge 1 ]] || { echo "Usage: tools/db.sh repair <env>" >&2; exit 1; }
    echo "repair only fixes Flyway's history table. It does NOT undo SQL."
    read -r -p "Have you undone any partial changes by hand? (yes/no) " ok
    [[ "$ok" == "yes" ]] || { echo "Cancelled."; exit 1; }
    flyway_for "$1" repair
    ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 1 ;;
esac
