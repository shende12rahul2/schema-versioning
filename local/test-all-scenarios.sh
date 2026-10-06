#!/usr/bin/env bash
# Runs ALL lab scenarios (local/README.md) from a clean lab and checks the results.
# For maintainers: run it after changing the lab, the tools or the example SQL.
#
#   local/test-all-scenarios.sh
#
# WARNING: deletes the lab database and resets db/migrations/ to Git
# (uncommitted changes there are lost). Needs Docker and bash (Linux, Mac, Git Bash).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export FLYWAY_PASSWORD=Lab_Passw0rd
LOG="$(mktemp)"
PASS=0; FAIL=0

db()  { tools/db.sh "$@" >"$LOG" 2>&1; }
lab() { local/lab.sh "$@" >"$LOG" 2>&1; }

check() {   # check "<description>" <expected exit 0|1> "<regex expected in output>"
  local desc="$1" want="$2" pattern="$3" got="$4"
  [[ "$got" -ne 0 ]] && got=1
  if [[ "$got" == "$want" ]] && grep -Eq "$pattern" "$LOG"; then
    echo "  PASS  $desc"; PASS=$((PASS+1))
  else
    echo "  FAIL  $desc (exit $got, expected $want; looked for: $pattern)"
    sed 's/^/        | /' "$LOG" | tail -15
    FAIL=$((FAIL+1))
  fi
}
clean_compare() {
  lab compare
  local n; n=$(grep -c "no rows selected" "$LOG")
  [[ "$n" -eq 5 ]] && echo ok >>"$LOG"
  check "compare: no differences" 0 "^ok$" "$([[ $n -eq 5 ]] && echo 0 || echo 1)"
}

echo "== Fresh lab"
git checkout -q -- db/migrations && git clean -qfd -- db/migrations
docker compose -f local/docker-compose.yml down -v >/dev/null 2>&1
lab up; check "lab up loads legacy schema" 0 "Lab is ready" $?

echo "== 01 onboard existing database"
db migrate local-dev;   check "migrate before baseline is refused" 1 "non-empty schema" $?
db baseline local-dev;  check "baseline records V1"                0 "baselined schema with version: 1" $?
db migrate local-dev;   check "migrate re-creates all code (8 R)"  0 "Successfully applied 8 migrations" $?

echo "== 02 fresh install"
db reset local-personal; check "reset builds V1 + 8 R"             0 "Successfully applied 9 migrations" $?
clean_compare

echo "== 03 new V file"
lab apply 03
db migrate local-personal; check "V file runs on personal"         0 "add pan to customer" $?
db migrate local-dev;      check "V file runs on dev"              0 "add pan to customer" $?
db migrate local-dev;      check "V file never runs twice"         0 "up to date" $?

echo "== 04 edit R file"
lab apply 04
db migrate local-personal; check "only the changed R file runs"    0 "Successfully applied 1 migration" $?
db migrate local-dev;      check "changed R file runs on dev"      0 "20 procedure add customer" $?

echo "== 05 V + R together"
lab apply 05
db migrate local-personal; check "V then R (2 migrations)"         0 "Successfully applied 2 migrations" $?
db migrate local-dev;      check "V then R on dev"                 0 "Successfully applied 2 migrations" $?

echo "== 06 failed V file"
lab apply 06
db migrate local-personal; check "broken V file fails"             1 "ORA-00942" $?
db migrate local-personal; check "migrate refused until repaired"  1 "Detected failed migration" $?
lab sql devx_local local/scenarios/06_failed_v_file/undo_partial_change.sql
check "undo partial change"                                       0 "Table altered" $?
lab apply 06 fix
echo yes | tools/db.sh repair local-personal >"$LOG" 2>&1
check "repair removes failed row"                                 0 "Successfully repaired" $?
db migrate local-personal; check "fixed V file runs"               0 "add kyc status" $?
db migrate local-dev;      check "fixed V file runs on dev"        0 "add kyc status" $?

echo "== 07 edited merged V file"
lab apply 07
db migrate local-personal; check "checksum mismatch stops migrate" 1 "checksum mismatch" $?
lab apply 03
db validate local-personal; check "validate passes after restore"  0 "Successfully validated" $?

echo "== 08 invalid object"
lab apply 08
db migrate local-personal; check "invalid view stops the run"      1 "invalid object.*after migrate" $?
lab apply 08 fix
db migrate local-personal; check "fixed view passes the check"     0 "30 view v loan summary" $?

echo "== 09 hand change on dev"
lab sql legacy_dev local/scenarios/09_manual_change_on_dev/hand_change.sql
db migrate local-dev;      check "flyway does not see hand change" 0 "up to date" $?
lab compare;               check "compare shows the drift"         0 "GET_CUSTOMER_NAME" $?
lab apply 09 fix
db migrate local-personal; check "R file with the change runs"     0 "20 function get customer name" $?
db migrate local-dev;      check "R file runs on dev"              0 "20 function get customer name" $?
clean_compare

echo "== 10 drop object"
lab apply 10
db migrate local-dev;      check "guarded drop on dev"             0 "drop get customer name" $?
db reset local-personal;   check "guarded drop on empty schema"    0 "Successfully applied 12 migrations" $?
clean_compare

echo "== 11 out-of-order merge"
lab apply 11
db migrate local-dev;      check "late file runs out of order"     0 "out of order" $?
db reset local-personal;   check "fresh install includes it"       0 "Successfully applied 13 migrations" $?
clean_compare

echo "== Safety"
db reset local-dev;        check "reset refused on shared dev"     1 "clean.*disabled|cleanDisabled" $?

echo "== Cleanup"
git checkout -q -- db/migrations && git clean -qfd -- db/migrations
rm -f "$LOG"
echo
echo "Result: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
