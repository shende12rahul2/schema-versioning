# Test data for developer databases

A developer database built with `tools\db reset` has the full structure and
reference data, but **no test data** – so the application has nothing to show.

`load_testdata.sql` adds a few customers and loan applications through the
real procedures (`ADD_CUSTOMER`, `LOAN_PKG`), so it also checks they work.

- Load it after every `tools\db reset` (see the file header for how).
- Flyway never runs it, so it can never reach shared Dev, QA, UAT or Prod.
- When a procedure it calls changes, update this file in the same pull request.
