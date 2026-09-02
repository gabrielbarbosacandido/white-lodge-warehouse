# 0001. Medallion layering with bronze-flags / silver-decides

- **Status:** accepted
- **Layer:** cross-cutting
- **Size:** L

## Problem

Cleaning logic has no natural home. Scattered across ingestion and models, "why is this row
missing?" becomes an archaeology exercise, which is exactly the question that gets asked live.

## Decision

Four zones, each with one job and an explicit permission to drop rows:

| Zone | Job | May drop rows? |
|---|---|---|
| `landing` (dlt) | source-shaped drop + quarantine | only to quarantine, with a reason |
| `bronze` (dbt) | type, rename, lineage, **flag** | never |
| `silver` (dbt) | clean, conform, resolve, enrich | yes, documented |
| `gold` (dbt) | star schema | no |

**Bronze flags, silver decides, gold presents.** A quality problem becomes a boolean column
in bronze, not a deletion.

## Why this and not the alternative

The obvious alternative is cleaning at ingest, which is cheaper: fewer models, fewer rows
carried. It was rejected because a row deleted in bronze is a row nobody can ever ask a
question about. `flag_duplicate_claim_id` in bronze means "how much revenue sits in the
rows we excluded?" is a query; deleting them in Python makes it a re-run.

Two-layer (staging/marts) was the starting shape. It worked, but it had no place to put a
quality signal that was not yet a decision, so signals and decisions kept collapsing into
the same model.

## Cost

More models (21 vs 13) and more rows materialised in views. At this volume that costs about
half a second. At 100× the bronze views would need reconsidering.

## Non-goals

Not a data-quality framework. No Great Expectations, no severity levels. Flags are plain
booleans and thresholds live in tests.

## Acceptance

- [x] `assert_bronze_drops_nothing`, bronze row count equals landing exactly
- [x] `assert_bronze_reconciles_to_silver`, bronze = silver + every documented exclusion
- [x] Every silver exclusion has a corresponding bronze flag or a join it fails

## Outcome

Implemented. Row flow reconciles exactly: 42,251 landing = 41,510 gold + 281 duplicate +
460 out-of-scope. The reconciliation test caught a real error during the restructure. An
early `slv_claims` filtered unknown partners as well as unknown pharmacies, which the count
identity exposed immediately.
