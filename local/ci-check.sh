#!/usr/bin/env bash
# Pull-request check: proves the database changes in this branch are safe.
# Used by .github/workflows/db-check.yml; can also be run locally (Linux, Mac, Git Bash).
#
#   local/ci-check.sh [base-ref]        base-ref defaults to origin/main
#
#   1. UPGRADE  - build "shared Dev" (LEGACY_DEV) from the base branch, then apply
#                 this branch on top - exactly what will happen to the real Dev.
#                 Catches: edited/deleted merged V files, failing SQL, INVALID objects.
#   2. FRESH    - build an empty developer database (DEVELOPER_DB) from this branch only.
#                 Catches: files that only work on an existing database.
#   3. COMPARE  - upgraded and fresh must be identical.
#
# WARNING: recreates the lab database (local/README.md) with empty schemas.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BASE="${1:-origin/main}"
export FLYWAY_PASSWORD=Lab_Passw0rd
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"; git checkout -q -- db/migrations 2>/dev/null; git clean -qfd -- db/migrations 2>/dev/null' EXIT

fail() { echo; echo "DATABASE CHECK FAILED: $*"; exit 1; }
step() { echo; echo "=== $*"; }

if ! git diff --quiet -- db/migrations || [[ -n "$(git ls-files --others --exclude-standard db/migrations)" ]]; then
  fail "db/migrations has uncommitted changes - commit them first."
fi

step "Start an empty lab database"
docker compose -f local/docker-compose.yml down -v >/dev/null 2>&1
LAB_LOAD_LEGACY=0 local/lab.sh up || fail "lab database did not start"

step "1. UPGRADE: build shared Dev from $BASE"
if git rev-parse --verify -q "$BASE^{commit}" >/dev/null && git cat-file -e "$BASE:db/migrations" 2>/dev/null; then
  mkdir -p "$WORK/head" && cp -R db/migrations/. "$WORK/head/"
  rm -rf db/migrations && mkdir -p db/migrations
  git archive "$BASE" db/migrations | tar -x -C "$WORK" && cp -R "$WORK/db/migrations/." db/migrations/
  tools/db.sh migrate local-dev || fail "the BASE branch ($BASE) does not build - fix main first"
  rm -rf db/migrations && mkdir -p db/migrations && cp -R "$WORK/head/." db/migrations/
  step "1. UPGRADE: apply this branch on top"
  tools/db.sh migrate local-dev || fail "this branch does not upgrade shared Dev cleanly (see the error above)"
else
  echo "No db/migrations on $BASE - upgrade check skipped."
  tools/db.sh migrate local-dev || fail "this branch does not build"
fi

step "2. FRESH: build an empty developer database from this branch"
tools/db.sh reset local-developer || fail "this branch does not build from an empty schema"

step "3. COMPARE: upgraded vs fresh"
OUT="$(local/lab.sh compare)"
echo "$OUT"
[[ "$(grep -c 'no rows selected' <<<"$OUT")" -eq 5 ]] \
  || fail "upgrading shared Dev and a fresh install give different databases (see the lists above)"

echo
echo "DATABASE CHECK PASSED: upgrade and fresh install both work and are identical."
