"""A dependency-free SQL shell over the warehouse.

`task query` opens it; `task query -- "select 1"` runs one statement and exits.
Always read-only, so it can never take the write lock from a dbt run.
"""

from __future__ import annotations

import sys

import duckdb

from white_lodge.settings import Settings


def _render(result) -> None:
    columns = result.columns
    rows = result.fetchall()
    if not rows:
        print("(0 rows)")
        return
    widths = [
        max(len(str(c)), max((len(str(r[i])) for r in rows), default=0))
        for i, c in enumerate(columns)
    ]
    line = "  ".join(str(c).ljust(w) for c, w in zip(columns, widths))
    print(line)
    print("  ".join("-" * w for w in widths))
    for row in rows[:200]:
        print("  ".join(str(v).ljust(w) for v, w in zip(row, widths)))
    if len(rows) > 200:
        print(f"... {len(rows) - 200:,} more rows")
    print(f"({len(rows):,} rows)")


def main() -> int:
    settings = Settings()
    if not settings.duckdb_path.exists():
        print(f"No warehouse at {settings.duckdb_path}, run `task build` first.", file=sys.stderr)
        return 1

    con = duckdb.connect(str(settings.duckdb_path), read_only=True)

    if len(sys.argv) > 1:
        _render(con.sql(" ".join(sys.argv[1:])))
        return 0

    print(f"White Lodge warehouse: {settings.duckdb_path} (read-only)")
    print("Medallion: landing -> bronze -> silver -> gold.  Start at gold.  Ctrl-D to exit.\n")
    while True:
        try:
            statement = input("wl> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        if not statement:
            continue
        if statement.lower() in {"exit", "quit", "\\q"}:
            return 0
        try:
            _render(con.sql(statement))
        except Exception as error:  # a bad query should not kill the session
            print(f"error: {error}", file=sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main())
