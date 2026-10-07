# Schema Versioning

All changes to our Oracle database are SQL files in this repository.
[Flyway](https://documentation.red-gate.com/flyway) runs them and remembers what already ran.

👉 **Start here: [docs/WORKFLOW.md](docs/WORKFLOW.md)** – the full workflow with diagrams.
📘 **Details: [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** – machine setup, team rollout, 11 worked examples, troubleshooting.
🧪 **Practise it: [local/README.md](local/README.md)** – a local Oracle in Docker with an example legacy schema and 22 step-by-step scenarios.

## In 30 seconds

- **Table / column / index / data change** → new **V file**: `tools\db new LOS-1234 add pan`
- **Procedure / view / package / trigger / grant** → edit its **R file**
- Test on your developer database: `tools\db migrate developer`
- Pull request → review → merge → DB lead runs `tools\db migrate dev`
- Never change shared Dev by hand. Never edit a merged V file.
- Safety checks run by themselves: wrong database, wiping a shared schema, edited V files,
  broken objects – and a **Database check** on every pull request (GitHub Actions).

## Folder layout

```
conf/
  flyway.conf                  shared settings (no passwords)
  env/dev.conf                 shared Dev database
  env/developer.conf.example    copy to developer.conf for your own schema
  env/local-*.conf             local practice lab only
db/
  migrations/versioned/        V files – run once, in order
  migrations/repeatable/       R files – one per code object, re-run when changed
  callbacks/                   automatic checks after every run
  legacy/                      old scripts, read-only archive (example LOS schema)
  testdata/                    test data for developer databases (never run by Flyway)
tools/
  db.cmd  (Windows)  /  db.sh  (Linux/Mac)   simple commands around Flyway
docs/
  WORKFLOW.md                  how we work – read this first
  DEVELOPER_GUIDE.md           detailed guide with examples
local/
  docker-compose.yml           local Oracle for practice
  lab.cmd / lab.sh             start the lab, open SQL, compare schemas, load scenarios
  scenarios/                   files for each practice scenario
```

## First-time setup on your machine

1. Install Docker Desktop (Flyway then runs from Docker), or the [Flyway CLI](https://documentation.red-gate.com/flyway/getting-started-with-flyway) on your `PATH`.
2. Copy `conf/env/developer.conf.example` → `conf/env/developer.conf` and fill in your schema name.
3. `set FLYWAY_PASSWORD=...` (Windows) or `export FLYWAY_PASSWORD=...` (Linux/Mac).
4. `tools\db reset` – builds your developer database from Git.
