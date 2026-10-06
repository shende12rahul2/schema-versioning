#!/usr/bin/env bash
# Local practice lab helper. See local/README.md.
#   local/lab.sh up | down | status | sql <schema> [file] | compare | apply <NN> [fix] | restore
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
COMPOSE="docker compose -f local/docker-compose.yml"
CONTAINER=schema-lab
PW=Lab_Passw0rd
CONN="//localhost:1521/FREEPDB1"

usage() {
  cat <<'TXT'
Usage: local/lab.sh <command>

  up                    Start the lab database (first start loads db/legacy, ~2-5 min)
  down                  Stop the lab and DELETE its data (next "up" starts fresh)
  status                Show whether the lab database is running
  sql <schema> [file]   Open SQL*Plus as legacy_dev | devx_local | system
                        (or run a .sql file)
  compare               Compare LEGACY_DEV ("shared Dev") with DEVX_LOCAL ("fresh install")
  apply <NN> [fix]      Copy scenario NN's files into db/migrations (see local/README.md)
  restore               Put db/migrations back exactly as it is in Git

For Flyway commands use tools/db.sh with env local-dev or local-personal,
after: export FLYWAY_PASSWORD=Lab_Passw0rd
TXT
}

scenario_dir() {
  local d
  d=$(ls -d local/scenarios/"$1"_*/ 2>/dev/null | head -1 || true)
  [[ -n "$d" ]] || { echo "No scenario $1 in local/scenarios/" >&2; exit 1; }
  echo "${d%/}"
}

cmd="${1:-help}"; shift || true
case "$cmd" in
  up)
    $COMPOSE up -d
    echo "Waiting for the database (first start: a few minutes)..."
    until docker logs "$CONTAINER" 2>&1 | grep -q "DATABASE IS READY TO USE"; do
      if docker logs "$CONTAINER" 2>&1 | grep -q "### Lab setup: loading" && \
         docker logs "$CONTAINER" 2>&1 | grep -qE "^ORA-|SP2-"; then
        echo "Setup error - check: docker logs $CONTAINER" >&2; exit 1
      fi
      sleep 5
    done
    echo "Lab is ready. LEGACY_DEV has the legacy schema, DEVX_LOCAL is empty."
    ;;
  down)
    $COMPOSE down -v
    ;;
  status)
    $COMPOSE ps
    ;;
  sql)
    [[ $# -ge 1 ]] || { echo "Usage: local/lab.sh sql <legacy_dev|devx_local|system> [file]" >&2; exit 1; }
    if [[ $# -ge 2 ]]; then
      docker exec -i "$CONTAINER" sqlplus -s -L "$1/$PW@$CONN" < "$2"
    else
      docker exec -it "$CONTAINER" sqlplus -L "$1/$PW@$CONN"
    fi
    ;;
  compare)
    docker exec -i "$CONTAINER" sqlplus -s -L "system/$PW@$CONN" < local/sql/compare_schemas.sql
    ;;
  apply)
    [[ $# -ge 1 ]] || { echo "Usage: local/lab.sh apply <NN> [fix]" >&2; exit 1; }
    sc=$(scenario_dir "$1")
    src="$sc/migrations"
    [[ "${2:-}" == "fix" ]] && src="$sc/fix/migrations"
    if [[ -d "$src" ]]; then
      cp -Rv "$src/." db/migrations/
    fi
    if [[ "${2:-}" != "fix" && -f "$sc/delete.txt" ]]; then
      while IFS= read -r f; do [[ -n "$f" ]] && rm -v "$f"; done < "$sc/delete.txt"
    fi
    echo "Applied $sc ${2:-}"
    ;;
  restore)
    echo "This removes ALL uncommitted changes and new files under db/migrations/."
    read -r -p "Continue? (yes/no) " ok
    [[ "$ok" == "yes" ]] || { echo "Cancelled."; exit 1; }
    git checkout -- db/migrations
    git clean -fd -- db/migrations
    ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 1 ;;
esac
