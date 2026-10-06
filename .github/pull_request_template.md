## Ticket
LOS-

## What changes in the database?


## Reviewer checklist
- [ ] Tables / columns / indexes / data → in a **new V file** (no merged V file was edited)
- [ ] Procedures / views / packages / triggers / grants → in their **R file**, `CREATE OR REPLACE`
- [ ] If a table was dropped/re-created: its trigger and grant R files were touched so they re-run
- [ ] Dropped object: its R file was deleted in this PR
- [ ] No passwords or connection secrets
- [ ] Author tested with `tools\db migrate personal` **and** a full `tools\db reset`
