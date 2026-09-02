# 0005. Every measure exists as gross and net

- **Status:** accepted
- **Layer:** gold
- **Size:** S

## Problem

A reverted claim must count as zero for revenue, volume, fees and payouts, but reversal
rate is itself a metric, so the rows cannot simply be deleted. Any single set of columns
serves one of those needs and silently breaks the other.

## Decision

`fct_claim` keeps every valid claim as a row and emits each measure twice: gross
(`price`, `pbm_fee`, `partner_fee`, `white_lodge_margin`) and net (`net_revenue`,
`net_pbm_fee`, `net_partner_fee`, `net_white_lodge_margin`, `net_fills`, …), where net is
zero when `is_reverted`. **Business totals sum the `net_*` columns.**

## Why this and not the alternative

A `WHERE NOT is_reverted` filter in every query is the alternative, and it fails the moment
someone forgets, with no error, just a quietly inflated number. Making the correct column
additive means the default aggregation is the right one.

A separate `fct_claim_reverted` table was rejected: it splits one grain across two tables
and makes reversal *rate* a union.

## Cost

Column count roughly doubles, and a reader must know which set to use. Mitigated by naming
(`net_` prefix), a README warning, and a test, but it is a genuine footgun for anyone who
skips both.

## Non-goals

Not a general soft-delete pattern. This applies to reversals only.

## Acceptance

- [x] `assert_reverted_claims_contribute_nothing`, reverted rows sum to zero on every net measure
- [x] `assert_gold_measures_reconcile`, `partner_fee + white_lodge_margin = pbm_fee`
- [x] Reverted claims are still countable: reversal rate is a ratio, not a union

## Outcome

Implemented. Reversal is resolved once in `slv_claim_economics`, so gold never re-derives
it and a new measure only has to follow the naming pair.
