# 0010. A revenue reconciliation model that proves nothing is lost

- **Status:** proposed
- **Layer:** gold
- **Size:** S

## Problem

Row-level reconciliation exists (`assert_bronze_reconciles_to_silver`), but **value**
reconciliation does not. We can prove 42,251 rows became 41,510 plus 741 documented
exclusions. We cannot show, in one query, how much *revenue* those exclusions represent.

"How much money is in the rows you threw away?" is a question a business lead will ask, and
right now it takes three ad-hoc queries.

## Decision

Add `gld_revenue_reconciliation`, one row per exclusion stage, with claim count and gross
price:

| stage | claims | gross_price |
|---|---|---|
| landed | 42,251 | … |
| rejected at ingest | 589 | *(unknown, payload is raw JSON)* |
| excluded: duplicate claim id | 281 | … |
| excluded: pharmacy not in reference | 460 | … |
| reverted | 2,764 | … |
| **net revenue in gold** | 38,746 | … |

## Why this and not the alternative

`analysis/queries/03_data_quality.sql` already counts rows per stage. Promoting it to a
model makes it testable, the stages must sum to the landed total, and turns a data-quality
curiosity into a business artifact.

## Cost

The ingest-rejected stage cannot report revenue: rejected payloads are stored as raw JSON,
and many were rejected *because* their price was unparseable. That row will carry a NULL
and a note, which is honest but slightly unsatisfying.

## Non-goals

No alerting or thresholds. This reports; it does not judge.

## Acceptance

- [ ] Stage claim counts sum exactly to `count(*)` in `bronze.brz_claims`
- [ ] Net revenue row equals `sum(net_revenue)` from `fct_claim`
- [ ] A test asserts both identities

## Outcome

*Not yet implemented.*
