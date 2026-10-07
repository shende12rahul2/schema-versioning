"""Which change is on which environment? (Linux/Mac version of tools/env-report.ps1)

Called by: tools/db.sh report [env ...]
Input:     one "<env>=<file>" argument per environment, each file holding the
           output of "flyway info -outputType=json" for that environment.
Output:    a Markdown table: one row per change, one column per environment.
"""
import json
import sys
from datetime import datetime


def load(path):
    """Return the Flyway JSON in a file (skipping any lines before it), or None."""
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return None
    start = text.find("{")
    if start < 0:
        return None
    try:
        data = json.loads(text[start:])
    except ValueError:
        return None
    return None if data.get("error") else data


def cell(m):
    """Short text for one migration's state in one environment."""
    state = m.get("state", "")
    day = (m.get("installedOnUTC") or "")[:10]
    if state in ("Success", "Baseline"):
        return "OK " + day
    if state == "Out of Order":
        return "OK " + day + " (late)"
    if state in ("Ignored (Baseline)", "Below Baseline"):
        return "baseline"
    if state == "Pending":
        return "PENDING"
    if state == "Outdated":
        return "CHANGED - not applied"
    if state == "Failed":
        return "FAILED"
    if state.startswith("Missing"):
        return "applied, file removed"
    if state.startswith("Future"):
        return "newer than Git"
    return state or "-"


def rows_for(data):
    """{row key: (sort key, label, cell text)} for one environment."""
    rows = {}
    for m in data.get("migrations", []):
        state = m.get("state", "")
        version = m.get("version") or ""
        if version:                                   # V file (or the baseline row)
            key = "V:" + version
            label = "V" + version + "  " + m.get("description", "")
            sort = (0, int(version) if version.isdigit() else 0, version)
            # Prefer the row that records an installation (baseline over "Ignored (Baseline)").
            if key in rows and not m.get("installedOnUTC"):
                continue
        else:                                         # R file: keep its latest, non-superseded state
            if state == "Superseded":
                continue
            key = "R:" + m.get("description", "")
            label = "R  " + m.get("description", "")
            sort = (1, 0, m.get("description", ""))
        rows[key] = (sort, label, cell(m))
    return rows


def main(args):
    envs, per_env = [], {}
    for arg in args:
        name, _, path = arg.partition("=")
        envs.append(name)
        data = load(path)
        per_env[name] = rows_for(data) if data is not None else None

    labels = {}
    for rows in per_env.values():
        for key, (sort, label, _) in (rows or {}).items():
            labels[key] = (sort, label)

    print("## Which change is on which environment")
    print()
    print("Generated " + datetime.now().strftime("%Y-%m-%d %H:%M") + " by `tools\\db report`.")
    print()
    print("| Change | " + " | ".join(envs) + " | Same everywhere |")
    print("|---|" + "---|" * len(envs) + "---|")
    for key, (_, label) in sorted(labels.items(), key=lambda kv: kv[1][0]):
        cells = []
        for env in envs:
            rows = per_env[env]
            cells.append("unreachable" if rows is None else rows.get(key, (None, None, "-"))[2])
        # Compare reachable environments only, without dates ("OK <date>" = applied).
        same = len({c.split(" ")[0] for c in cells if c != "unreachable"}) <= 1
        print("| " + label + " | " + " | ".join(cells) + " | " + ("yes" if same else "**NO**") + " |")

    print()
    for env in envs:
        rows = per_env[env]
        if rows is None:
            print("- **" + env + "**: could not connect (check conf/env/" + env + ".conf and the password)")
            continue
        cells = [c for (_, _, c) in rows.values()]
        pending = sum(c in ("PENDING", "CHANGED - not applied") for c in cells)
        failed = sum(c == "FAILED" for c in cells)
        status = "up to date" if not pending and not failed else \
            f"{pending} change(s) waiting" + (f", {failed} FAILED" if failed else "")
        print("- **" + env + "**: " + status)


if __name__ == "__main__":
    main(sys.argv[1:])
