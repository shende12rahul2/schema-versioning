# Local Practice Lab

Practise the whole workflow on your own machine, with no risk to the real databases.

The lab is **one Oracle database in Docker** with two schemas:

| Lab schema | Plays the role of | Flyway env | Starts as |
|---|---|---|---|
| `LEGACY_DEV` | the existing **shared Dev** database | `local-dev` | loaded from [`db/legacy/`](../db/legacy/README.md) (tables, code, test data) |
| `DEVX_LOCAL` | **your personal schema** | `local-personal` | empty |

Plus `APP_READER`, a read-only API user that receives grants.

---

## What you need

- **Docker Desktop** (running)
- **Flyway CLI** on your `PATH` ([download](https://documentation.red-gate.com/flyway/getting-started-with-flyway) – the Windows zip includes Java)
- About 3 GB of free disk space

All lab passwords are `Lab_Passw0rd` (local container only, never use it anywhere else).

> Examples use Windows commands (`tools\db`, `local\lab`).
> On Linux/Mac use `tools/db.sh` and `local/lab.sh` instead.

---

## Start the lab

```bat
local\lab up
set FLYWAY_PASSWORD=Lab_Passw0rd
```

The first start downloads Oracle and loads the legacy scripts (a few minutes).
Check what the "shared Dev" looks like:

```bat
local\lab sql legacy_dev
SQL> SELECT object_type, object_name FROM user_objects ORDER BY 1, 2;
SQL> SELECT * FROM v_loan_summary;
SQL> exit
```

Useful commands during the lab:

| Command | What it does |
|---|---|
| `local\lab sql legacy_dev` | SQL*Plus on "shared Dev" (also `devx_local`, `system`) |
| `local\lab compare` | Differences between "shared Dev" and your "personal schema" |
| `local\lab apply 03` | Copy scenario 03's files into `db\migrations\` |
| `local\lab apply 06 fix` | Copy the **fixed** files of scenario 06 |
| `local\lab restore` | Put `db\migrations\` back as it is in Git |
| `local\lab down` | Delete the lab completely (next `up` starts fresh) |

---

## Scenarios

Do them **in order** – each one builds on the previous.
To start again from zero at any time: `local\lab down`, `local\lab restore`, `local\lab up`.

### 01 · Onboard the existing database (one time)

*Bring the legacy "shared Dev" under Flyway without re-creating it.*

```bat
tools\db info local-dev
```
Everything is *Pending* – Flyway has never seen this schema.
(If you try `migrate` now, Flyway refuses: *"Found non-empty schema without
schema history table"*. That protects existing databases.)

```bat
tools\db baseline local-dev
tools\db info local-dev
```
V1 now shows as **Baseline**: Flyway recorded "V1 is done" **without running it**
(the tables already exist).

```bat
tools\db migrate local-dev
tools\db info local-dev
```
All R files ran: every code object was re-created from Git. V1 did not run.
The invalid-object check after the run passed.

✅ **Learned:** `baseline` only *records* the starting point. Then `migrate`
makes Git the owner of all code objects.

### 02 · Fresh install on an empty schema

*Prove that V1 + R files build the same database from nothing.*

```bat
tools\db reset local-personal
local\lab compare
```
`DEVX_LOCAL` is built from Git: V1 first, then all R files.
`compare` should show **no rows** in sections 1–5, and the same grants in 6.

Try it: in `local\lab compare`, why does the legacy `CUSTOMER.EMAIL` column
match? Because V1 includes the 2024 hotfix (`db/legacy/09_…`). Remove `email`
from V1, `reset` again and `compare` – you will see the difference.
(Put it back afterwards and `reset` again.)

✅ **Learned:** V1 must describe the **real** database, not just the old scripts.
Test data (`10_sample_data.sql`) is not part of V1.

### 03 · New V file (add a column)

```bat
local\lab apply 03
tools\db migrate local-personal
tools\db migrate local-dev
tools\db info local-dev
```
`V20261007100000__LOS1234_add_pan_to_customer.sql` ran **once** on each schema.
Run `migrate` again: *"Schema is up to date"* – it never runs twice.

In real work you create the file with `tools\db new LOS-1234 add pan to customer`.

### 04 · Change a procedure (edit an R file)

```bat
local\lab apply 04
tools\db migrate local-personal
tools\db info local-personal
```
Only `R__20_procedure_add_customer.sql` ran again (it changed). The other
R files did not run. Try the new parameter:

```bat
local\lab sql devx_local
SQL> VARIABLE id NUMBER
SQL> EXEC add_customer('Neha Joshi', '9800000003', :id, 'ABCDE1234F');
SQL> SELECT customer_id, full_name, pan_number FROM customer;
SQL> exit
```
Then `tools\db migrate local-dev`.

### 05 · V file and R file together

```bat
local\lab apply 05
tools\db migrate local-personal
tools\db info local-personal
```
New column `LOAN_APPLICATION.BRANCH_CODE` (V file) **first**, then the
changed view `V_LOAN_SUMMARY` that uses it (R file). Then `tools\db migrate local-dev`.

✅ **Learned:** every run = pending V files, then changed R files.

### 06 · A V file fails half-way

```bat
local\lab apply 06
tools\db migrate local-personal
```
❌ Fails: `ORA-00942: table or view does not exist` (`customer_typo`).

Look at the damage:
```bat
tools\db info local-personal
local\lab sql devx_local
SQL> DESC customer
SQL> exit
```
`info` shows the version as **Failed** (and `migrate` now refuses to run until it is repaired), and `KYC_STATUS` **was added** – Oracle
does not roll back DDL. Recover:

```bat
local\lab sql devx_local local\scenarios\06_failed_v_file\undo_partial_change.sql
local\lab apply 06 fix
tools\db repair local-personal
tools\db migrate local-personal
```
1. undo what already ran, 2. fix the V file (allowed – it never succeeded),
3. `repair` removes the *Failed* row, 4. run again.
Then `tools\db migrate local-dev` (the fixed file runs cleanly there).

✅ **Learned:** `repair` only cleans Flyway's history. **You** undo the SQL.

### 07 · Someone edits a V file that already ran

```bat
local\lab apply 07
tools\db migrate local-personal
```
❌ Fails: *"Migration checksum mismatch for migration version 20261007100000"*.
Flyway protects you: that file already ran everywhere, editing it changes nothing
in the databases but makes Git lie.

Fix: put the file back, and make a **new** V file if a change is really needed.
```bat
local\lab apply 03
tools\db validate local-personal
```

✅ **Learned:** never edit a merged V file.

### 08 · A change leaves an object INVALID

```bat
local\lab apply 08
tools\db migrate local-personal
```
❌ The view is created (Flyway only prints *"Warning: execution completed with
warning (… Error Code: 17110)"* – Oracle's way of saying "created with
compilation errors"), but the automatic check after the run stops it:
*"1 invalid object(s) after migrate: VIEW V_LOAN_SUMMARY"* (`c.pan_no` does not exist).

```bat
local\lab apply 08 fix
tools\db migrate local-personal
```
The corrected R file runs again and the check passes. Broken code never reaches Dev.

### 09 · Someone changes shared Dev by hand

```bat
local\lab sql legacy_dev local\scenarios\09_manual_change_on_dev\hand_change.sql
tools\db migrate local-dev
local\lab compare
```
`migrate` says *up to date* – **Flyway does not notice hand changes.**
`compare` (section 4) shows `GET_CUSTOMER_NAME` differs from a fresh install:
Git is now wrong, and the next edit of that R file would silently remove the hand fix.

Fix: put the change into Git.
```bat
local\lab apply 09 fix
tools\db migrate local-personal
tools\db migrate local-dev
local\lab compare
```
Section 4 is empty again.

✅ **Learned:** no hand changes on shared Dev. If it happens, copy it into the R file.

### 10 · Drop an object

```bat
local\lab apply 10
tools\db migrate local-dev
tools\db reset local-personal
local\lab compare
```
`apply 10` adds a V file with a **guarded** `DROP FUNCTION get_customer_name`
and deletes its R file.
- On `local-dev` the function exists → it is dropped.
- On a fresh install all V files run before any R file, so the function does not
  exist yet → the guard skips the drop instead of failing.

✅ **Learned:** drop in a V file (guarded), delete the R file in the same change.

### 11 · A teammate's change is merged late (out of order)

```bat
local\lab apply 11
tools\db migrate local-dev
tools\db info local-dev
```
`V20261007120000__LOS1250_add_loan_tenure.sql` has an **older** timestamp than
files that already ran. It still runs once and `info` marks it **Out of Order**.
That is normal with several developers.

```bat
tools\db reset local-personal
local\lab compare
```
A fresh install runs it in timestamp order and gives the same result.

---

## Finish

```bat
local\lab restore
local\lab down
```
`restore` removes the scenario files from `db\migrations\` so they are never committed.
