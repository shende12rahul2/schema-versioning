# Schema Versioning

All changes to our Oracle database are SQL files in this repository.
[Flyway](https://documentation.red-gate.com/flyway) runs them and remembers what already ran.

👉 **Start here: [docs/WORKFLOW.md](docs/WORKFLOW.md)** – the full workflow with diagrams.
🧪 **Practise it: [local/README.md](local/README.md)** – a local Oracle in Docker with an example legacy schema and 11 step-by-step scenarios.

## In 30 seconds

- **Table / column / index / data change** → new **V file**: `tools\db new LOS-1234 add pan`
- **Procedure / view / package / trigger / grant** → edit its **R file**
- Test on your personal schema: `tools\db migrate personal`
- Pull request → review → merge → DB lead runs `tools\db migrate dev`
- Never change shared Dev by hand. Never edit a merged V file.

## Folder layout

```
conf/
  flyway.conf                  shared settings (no passwords)
  env/dev.conf                 shared Dev database
  env/personal.conf.example    copy to personal.conf for your own schema
  env/local-*.conf             local practice lab only
db/
  migrations/versioned/        V files – run once, in order
  migrations/repeatable/       R files – one per code object, re-run when changed
  callbacks/                   automatic checks after every run
  legacy/                      old scripts, read-only archive (example LOS schema)
tools/
  db.cmd  (Windows)  /  db.sh  (Linux/Mac)   simple commands around Flyway
docs/
  WORKFLOW.md                  how we work – read this first
local/
  docker-compose.yml           local Oracle for practice
  lab.cmd / lab.sh             start the lab, open SQL, compare schemas, load scenarios
  scenarios/                   files for each practice scenario
```

## First-time setup on your machine

1. Install [Flyway CLI](https://documentation.red-gate.com/flyway/getting-started-with-flyway) and put it on your `PATH`.
2. Copy `conf/env/personal.conf.example` → `conf/env/personal.conf` and fill in your schema name.
3. `set FLYWAY_PASSWORD=...` (Windows) or `export FLYWAY_PASSWORD=...` (Linux/Mac).
4. `tools\db reset` – builds your personal schema from Git.
