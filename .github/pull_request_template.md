## Ticket
LOS-

## What changes in the database?


## Reviewer checklist (docs/DEVELOPER_GUIDE.md, section 9)
- [ ] Tables / columns / indexes / data → in a **new V file**; no merged V file edited
- [ ] Code objects → in **their own R file**, `CREATE OR REPLACE` (views `FORCE`), PL/SQL ends with `/`
- [ ] Renamed / dropped columns: every R file using them is updated
- [ ] Table dropped/recreated: its trigger and grant R files are touched
- [ ] Dropped object: guarded drop + R file deleted
- [ ] New objects the API needs have grants
- [ ] Data changes are safe to run on any database (MERGE / WHERE), no test data
- [ ] No passwords, no `COMMIT` / `EXIT` / `SET` / `PROMPT`
- [ ] Author ran `tools\db migrate personal` **and** a full `tools\db reset`
