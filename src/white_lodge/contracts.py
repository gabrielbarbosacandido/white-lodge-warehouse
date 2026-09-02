"""Structural validation, tier 1 of two.

Tier 1 (here, at ingest): can this record be *parsed* into its declared schema?
Missing required fields, unparseable timestamps, and non-numeric numerics are
structural failures. A record that fails is quarantined with a reason, never
silently dropped and never coerced. We do not try to read "one hundred" as 100,
because guessing intent on a corrupt row is how bad revenue numbers are born.

Tier 2 (dbt, post-load): set-level and semantic rules that need the whole
table: duplicate claim ids, the pharmacy-exists filter, `pbm_fee > price`. Those are
tested and handled in SQL where they are visible and easy to change.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

CLAIM_FIELDS = ("id", "npi", "ndc", "price", "quantity", "pbm_fee", "timestamp")
REVERT_FIELDS = ("id", "claim_id", "timestamp")
LOOKUP_FIELDS = ("id", "ndc", "partner", "channel", "timestamp")  # claim_id is nullable


def _missing(record: dict[str, Any], fields: tuple[str, ...]) -> str | None:
    absent = [f for f in fields if record.get(f) is None]
    return f"missing_required_field:{','.join(sorted(absent))}" if absent else None


def _timestamp(value: Any) -> datetime | None:
    if not isinstance(value, str):
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


def _number(value: Any) -> float | None:
    """Accept int/float only. Numeric-looking strings are accepted; words are not."""
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value.strip())
        except ValueError:
            return None
    return None


def validate_claim(record: dict[str, Any]) -> tuple[dict[str, Any] | None, str | None]:
    if reason := _missing(record, CLAIM_FIELDS):
        return None, reason

    ts = _timestamp(record["timestamp"])
    if ts is None:
        return None, "unparseable_timestamp"

    price = _number(record["price"])
    quantity = _number(record["quantity"])
    pbm_fee = _number(record["pbm_fee"])
    non_numeric = [
        f for f, v in (("price", price), ("quantity", quantity), ("pbm_fee", pbm_fee)) if v is None
    ]
    if non_numeric:
        return None, f"non_numeric:{','.join(non_numeric)}"

    if price < 0:
        return None, "negative_price"
    if quantity <= 0:
        return None, "non_positive_quantity"

    return {
        "claim_id": record["id"],
        "npi": str(record["npi"]),
        "ndc": str(record["ndc"]),
        "price": price,
        "quantity": quantity,
        "pbm_fee": pbm_fee,
        "filled_at": ts,
    }, None


def validate_revert(record: dict[str, Any]) -> tuple[dict[str, Any] | None, str | None]:
    if reason := _missing(record, REVERT_FIELDS):
        return None, reason
    ts = _timestamp(record["timestamp"])
    if ts is None:
        return None, "unparseable_timestamp"
    return {
        "revert_id": record["id"],
        "claim_id": record["claim_id"],
        "reverted_at": ts,
    }, None


def validate_lookup(record: dict[str, Any]) -> tuple[dict[str, Any] | None, str | None]:
    if reason := _missing(record, LOOKUP_FIELDS):
        return None, reason
    ts = _timestamp(record["timestamp"])
    if ts is None:
        return None, "unparseable_timestamp"
    return {
        "lookup_id": record["id"],
        "claim_id": record.get("claim_id"),
        "ndc": str(record["ndc"]),
        "partner": record["partner"],
        "channel": record["channel"],
        "looked_up_at": ts,
    }, None
