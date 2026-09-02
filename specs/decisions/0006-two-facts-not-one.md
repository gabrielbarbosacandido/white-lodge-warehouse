# 0006. Two facts (claim, lookup) rather than one wide table

- **Status:** accepted
- **Layer:** gold
- **Size:** S

## Problem

Lookups and claims are linked (`lookup.claim_id`) but 76% of lookups never convert:
175,835 lookups against 41,510 claims. One table has to represent both grains.

## Decision

Two facts: `fct_claim` (one valid in-scope claim) and `fct_lookup` (one lookup), conformed
on `dim_drug`, `dim_partner` and `dim_date`. `fct_lookup` carries claim-side context as
nullable columns for funnel questions in a single scan.

## Why this and not the alternative

One wide lookup-grain table would force every revenue query to filter to converted rows,
which is the same silent-wrong-number failure as decision 0005. It would also turn "conversion rate"
into a question about NULL density instead of a ratio of two counts, and multiply claim
measures across lookup rows for any claim reached by more than one lookup.

One wide *claim*-grain table simply cannot represent the 134,000 lookups that never
converted, which is where most of the funnel signal lives.

## Cost

Funnel questions spanning both facts need a join, and claim-side columns are duplicated
into `fct_lookup` for convenience, denormalisation that must stay in sync.

## Non-goals

No bridge table. The relationship is verified 1:1 here and a `qualify` keeps it 1:1 if that
changes.

## Acceptance

- [x] `fct_lookup` row count equals `silver.slv_lookups` exactly, no fan-out
- [x] Conversion rate is `sum(converted_to_valid_claim) / count(*)` on one table
- [x] Both facts join cleanly to all three conformed dimensions

## Outcome

Implemented. Conversion comes out at 23.1% overall, and the partner/channel cut in
`analysis/queries/02_conversion_funnel.sql` is a single GROUP BY.
