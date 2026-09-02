"""Claim / revert / lookup event streams.

No primary key is declared here on purpose: uniqueness is a *set-level* rule
(claim ids collide in this data), so it is enforced and made visible in dbt
rather than silently deduped at ingest.

The event files *are* the stream: each source is a directory of JSON files, read
as a batch. Every record is validated structurally; clean records go to the
stream's table, failures go to `<stream>_rejects` with the raw payload and a
reason, so "how much did we drop, and why" is a query rather than a log grep.
"""

from __future__ import annotations

import json
from collections.abc import Iterator
from pathlib import Path
from typing import Any, Callable

import dlt

from white_lodge.contracts import validate_claim, validate_lookup, validate_revert


def _read_json_dir(directory: Path) -> Iterator[tuple[dict[str, Any], str]]:
    """Yield (record, source_file) for every record in every JSON file."""
    for path in sorted(Path(directory).glob("*.json")):
        try:
            payload = json.loads(path.read_text())
        except json.JSONDecodeError:
            continue  # a whole unreadable file is reported by the caller's counters
        for record in payload if isinstance(payload, list) else [payload]:
            if isinstance(record, dict):
                yield record, path.name


def _stream(directory: Path, validate: Callable, rejects_table: str) -> Iterator[dict[str, Any]]:
    for record, source_file in _read_json_dir(directory):
        clean, reason = validate(record)
        if clean is None:
            yield dlt.mark.with_table_name(
                {
                    "raw_payload": json.dumps(record),
                    "reject_reason": reason,
                    "_source_file": source_file,
                },
                rejects_table,
            )
        else:
            yield {**clean, "_source_file": source_file}


@dlt.resource(name="claims", write_disposition="replace")
def claims(directory: Path) -> Iterator[dict[str, Any]]:
    yield from _stream(directory, validate_claim, "claims_rejects")


@dlt.resource(name="reverts", write_disposition="replace")
def reverts(directory: Path) -> Iterator[dict[str, Any]]:
    yield from _stream(directory, validate_revert, "reverts_rejects")


@dlt.resource(name="lookups", write_disposition="replace")
def lookups(directory: Path) -> Iterator[dict[str, Any]]:
    yield from _stream(directory, validate_lookup, "lookups_rejects")
