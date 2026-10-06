# Legacy scripts (read-only archive)

The **original** SQL scripts the DB team used before version control, kept
exactly as they were. **Do not edit or run them against shared databases.**
From now on, all changes go into `db/migrations/`
(see [docs/WORKFLOW.md](../../docs/WORKFLOW.md)).

The files here are a small **example** (a loan-origination "LOS" schema) used by
the local practice lab in [`local/`](../../local/README.md). Replace them with
your real legacy scripts.

| File | What it contains | Where it went in `db/migrations/` |
|---|---|---|
| `01_tables.sql` | Tables, keys, indexes | `V1__initial_schema.sql` |
| `02_sequences.sql` | Sequences | `V1__initial_schema.sql` |
| `03_reference_data.sql` | Loan status codes | `V1__initial_schema.sql` |
| `04_functions_procedures.sql` | `GET_CUSTOMER_NAME`, `ADD_CUSTOMER` | one R file each |
| `05_packages.sql` | `LOAN_PKG` spec + body | `R__10_…spec`, `R__40_…body` |
| `06_views.sql` | `V_LOAN_SUMMARY` | `R__30_view_v_loan_summary.sql` |
| `07_triggers.sql` | `CUSTOMER_BI`, `LOAN_APPLICATION_AUD` | one R file each |
| `08_grants.sql` | Grants to `APP_READER` | `R__60_grants_app_reader.sql` |
| `09_hotfix_2024_03_add_email.sql` | Hand hotfix: `CUSTOMER.EMAIL` | **merged into V1** (the real DB has it) |
| `10_sample_data.sql` | Test customers / loans | **not migrated** – test data never goes in V1 |
| `install_all.sql` | Runs everything in order (SQL*Plus) | not needed any more |

Things to notice (they are typical for legacy scripts):

- `09_hotfix…` changed the real database, but `01_tables.sql` was never
  updated. V1 must describe what the **real** database has.
- `PROMPT`, `SET DEFINE OFF`, `SHOW ERRORS`, `EXIT` are SQL*Plus commands.
  Flyway does not need them, so they were removed from the migration files.
- Code objects (procedures, packages, views, triggers, grants) were split into
  one R file per object.
