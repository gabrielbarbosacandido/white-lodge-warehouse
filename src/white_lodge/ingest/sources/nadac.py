"""NADAC, external drug acquisition cost benchmark, streamed from CMS.

CMS publishes one CSV per year containing a rolling series of *weekly snapshots*:
the 2026 file carries 34 distinct `As of Date` values over ~1.03M rows. So a drug
has no single cost, and the as-of choice is made downstream in dbt
(`int_nadac_asof`) where it is visible and changeable, not hidden in ingestion.

We take 8 of the 12 published columns:
  NDC, NADAC Per Unit, Effective Date, As of Date  -> the cost and its as-of keys
  Pricing Unit                                     -> guards unit-mismatch errors
  NDC Description, Classification for Rate Setting, OTC -> drug attributes for
                                                          dim_drug and the
                                                          generic/brand margin cut
Dropped: Pharmacy Type Indicator, Explanation Code, and the two "Corresponding
Generic Drug" columns, none feed a metric we defined.
"""

from __future__ import annotations

import codecs
import csv
from collections.abc import Iterator
from datetime import date, datetime
from pathlib import Path
from typing import Any

import dlt
import requests

COLUMNS = {
    "NDC": "ndc",
    "NDC Description": "ndc_description",
    "NADAC Per Unit": "nadac_per_unit",
    "Effective Date": "effective_date",
    "As of Date": "as_of_date",
    "Pricing Unit": "pricing_unit",
    "Classification for Rate Setting": "rate_setting_class",
    "OTC": "is_otc",
}


def _date(value: str) -> date | None:
    try:
        return datetime.strptime((value or "").strip(), "%m/%d/%Y").date()
    except ValueError:
        return None


def _rows(url: str, cache_dir: Path) -> Iterator[dict[str, str]]:
    """Stream the CSV from CMS, caching it so re-runs are offline and fast."""
    cache_dir = Path(cache_dir)
    cache_dir.mkdir(parents=True, exist_ok=True)
    cached = cache_dir / Path(url).name

    if cached.exists():
        with cached.open(newline="", encoding="utf-8-sig") as handle:
            yield from csv.DictReader(handle)
        return

    with requests.get(url, stream=True, timeout=300) as response:
        response.raise_for_status()
        tmp = cached.with_suffix(".partial")
        with tmp.open("wb") as sink:
            reader = csv.DictReader(
                codecs.iterdecode(_tee(response.iter_lines(), sink), "utf-8-sig")
            )
            yield from reader
        tmp.replace(cached)


def _tee(lines: Iterator[bytes], sink) -> Iterator[bytes]:
    for line in lines:
        sink.write(line + b"\n")
        yield line


@dlt.resource(name="nadac", write_disposition="replace")
def nadac(url: str, cache_dir: Path) -> Iterator[dict[str, Any]]:
    for row in _rows(url, cache_dir):
        per_unit = (row.get("NADAC Per Unit") or "").strip()
        try:
            cost = float(per_unit)
        except ValueError:
            continue  # a snapshot row with no usable cost carries no information
        yield {
            "ndc": (row.get("NDC") or "").strip(),
            "ndc_description": (row.get("NDC Description") or "").strip(),
            "nadac_per_unit": cost,
            "effective_date": _date(row.get("Effective Date", "")),
            "as_of_date": _date(row.get("As of Date", "")),
            "pricing_unit": (row.get("Pricing Unit") or "").strip(),
            "rate_setting_class": (row.get("Classification for Rate Setting") or "").strip(),
            "is_otc": (row.get("OTC") or "").strip().upper() == "Y",
        }
