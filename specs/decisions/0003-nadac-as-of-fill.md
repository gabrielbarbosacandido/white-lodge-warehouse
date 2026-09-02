# 0003. Price claims at the NADAC snapshot as-of the fill date

- **Status:** accepted
- **Layer:** silver
- **Size:** M

## Problem

NADAC is a rolling series of weekly snapshots, 34 for 2026, 1.03M rows, 32,509 NDCs. The
same NDC appears many times with different `as_of_date`. "The cost of this drug" is not a
single number, so joining on `ndc` alone is ambiguous and would fan out 34×.

## Decision

Price each claim at the most recent snapshot published on or before its fill date, using
DuckDB's `ASOF JOIN`. Exposed as `nadac_cost_basis`, default `as_of_fill`, alternative
`latest`.

## Why this and not the alternative

`latest`, meaning one snapshot for everything, is simpler, faster and fully covered. It was
rejected because it back-dates August prices onto March fills, which erases cost drift
across the window. Cost drift is precisely what a margin question is asking about, so the
simpler basis destroys the signal the model exists to surface.

`ASOF JOIN` was chosen over a correlated subquery or a window-ranked join because it states
the intent directly and does it in one pass.

## Cost

More expensive than an equijoin. Claims filled before the first available snapshot get no
cost rather than a back-filled value, accepted, because inventing a cost is worse than
admitting to none. Three NDCs (571 claims, 1.4%) never match at all and carry
`flag_cost_unavailable`; they stay in the fact table because dropping revenue to fix a cost
gap is the wrong trade.

## Non-goals

No use of `effective_date`, and no interpolation between snapshots. No ingestion of NADAC
years other than 2026.

## Acceptance

- [x] Every costed claim's `cost_as_of_date` is ≤ its `filled_date`
- [x] Claim count is unchanged by the join (no fan-out)
- [x] `--vars 'nadac_cost_basis: latest'` builds and changes only cost columns

## Outcome

Implemented in `slv_claim_costs`. Both bases build cleanly, which makes the sensitivity of
any margin answer to the cost basis demonstrable in about ten seconds, a useful thing to
be able to show rather than assert.
