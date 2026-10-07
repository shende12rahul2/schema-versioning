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
  migrate <env>                Apply pending changes (env = developer | dev | ...)
  info <env>                   Show what has run and what is pending
  validate <env>               Check Git files against what already ran
  reset [env]                  DEVELOPER database only: wipe it and rebuild from Git
                               (env defaults to "developer"; shared envs refuse)
  baseline <env>               ONE TIME, existing database: mark it as "already at V1"
  repair <env>                 Fix the history table after a failed run (see docs)
  report [env ...]             Which change is on which environment (read-only table;
                               default: every conf/env/*.conf except developer/local-*)

Password: set FLYWAY_PASSWORD before running. It is never stored in Git.
Flyway: uses the "flyway" command if installed, otherwise the flyway/flyway Docker image.
TXT
}

flyway_for() {
  local env="$1"; shift
  local conf="conf/env/${env}.conf"
  if [[ ! -f "$conf" ]]; then
    echo "ERROR: $conf not found." >&2
    [[ "$env" == "developer" ]] && echo "Copy conf/env/developer.conf.example to conf/env/developer.conf first." >&2
    exit 1
  fi
  echo ">> Environment: $env"
  if command -v flyway >/dev/null 2>&1; then
    flyway "-configFiles=conf/flyway.conf,${conf}" "$@"
  elif command -v docker >/dev/null 2>&1; then
    # No Flyway installed: run the official Flyway Docker image instead.
    # Inside the container "localhost" is the container itself, so point it at the host.
    local url
    url="$(grep '^flyway.url=' "$conf" | cut -d= -f2- | sed 's/@\/\/localhost:/@\/\/host.docker.internal:/')"
    docker run --rm --add-host=host.docker.internal:host-gateway \
      -e FLYWAY_PASSWORD -v "$ROOT:/work" -w /work "${FLYWAY_IMAGE:-flyway/flyway:latest}" \
      "-configFiles=conf/flyway.conf,${conf}" "-url=${url}" "$@"
  else
    echo "ERROR: Flyway not found. Install the Flyway CLI or Docker." >&2
    exit 1
  fi
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
    env="$1"; shift
    flyway_for "$env" "$cmd" "$@"
    ;;
  reset)
    env="${1:-developer}"
    echo "This WIPES the $env schema and rebuilds it from Git."
    flyway_for "$env" clean
    flyway_for "$env" migrate
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
  report)
    if [[ $# -eq 0 ]]; then
      for f in conf/env/*.conf; do
        n="$(basename "$f" .conf)"
        [[ "$n" == developer || "$n" == local-* ]] || set -- "$@" "$n"
      done
    fi
    command -v python3 >/dev/null 2>&1 || { echo "ERROR: report needs python3 (on Windows use tools\\db report)." >&2; exit 1; }
    tmp="$(mktemp -d)"; args=()
    for e in "$@"; do
      echo ">> Reading $e ..." >&2
      ( flyway_for "$e" info -outputType=json ) >"$tmp/$e.json" 2>/dev/null || true
      args+=("$e=$tmp/$e.json")
    done
    python3 "$ROOT/tools/env_report.py" "${args[@]}"
    rm -rf "$tmp"
    ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 1 ;;
esac
