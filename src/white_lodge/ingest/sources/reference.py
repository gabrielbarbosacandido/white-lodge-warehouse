"""Pharmacy and partner reference data.

Slowly-changing in the real world; fully reloaded here (see README for what
SCD-2 would change). Small enough that a plain CSV read is the right tool.
"""

from __future__ import annotations

import csv
from collections.abc import Iterator
from pathlib import Path
from typing import Any

import dlt


def _read_csv_dir(directory: Path) -> Iterator[dict[str, str]]:
    for path in sorted(Path(directory).glob("*.csv")):
        with path.open(newline="") as handle:
            yield from csv.DictReader(handle)


def _to_float(value: str) -> float | None:
    value = (value or "").strip()
    if value == "":
        return None
    try:
        return float(value)
    except ValueError:
        return None


@dlt.resource(name="pharmacies", write_disposition="replace", primary_key="npi")
def pharmacies(directory: Path) -> Iterator[dict[str, Any]]:
    for row in _read_csv_dir(directory):
        if row.get("npi"):
            yield {"npi": str(row["npi"]).strip(), "chain": (row.get("chain") or "").strip()}


@dlt.resource(name="partners", write_disposition="replace", primary_key="partner")
def partners(directory: Path) -> Iterator[dict[str, Any]]:
    for row in _read_csv_dir(directory):
        if not row.get("partner"):
            continue
        # fee_cents=0 is a real term (Airflow Rx), not a missing value, keep the
        # distinction between 0 and NULL intact all the way through.
        yield {
            "partner": row["partner"].strip(),
            "fee_cents": _to_float(row.get("fee_cents", "")),
            "fee_percentage": _to_float(row.get("fee_percentage", "")),
        }
