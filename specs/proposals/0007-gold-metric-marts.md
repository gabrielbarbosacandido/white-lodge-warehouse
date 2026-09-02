# 0007. Gold metric marts so a metric has one definition

- **Status:** proposed
- **Layer:** gold
- **Size:** S

## Problem

"Most valuable partner" is currently a GROUP BY someone writes from memory. It has at least
three defensible answers in this data, and they disagree, for the meridian chain, Kafka Rx
leads on retained margin ($19,478) while Hudi Rx leads on claim volume and Flink Rx is
second on revenue but nearly last on margin, because it takes 80% of the fee.

Two people asked the same question will compute different numbers, and neither will be
wrong.

## Decision

Add two gold marts that pin the definitions:

- `gld_partner_performance`, grain: partner × chain × month. Columns: claims, fills,
  revenue, fee collected, fee paid out, margin retained, payout ratio, revert rate.
- `gld_conversion_funnel`, grain: partner × channel × month. Columns: lookups, claims,
  conversion rate, revert rate, margin per lookup.

Both built on `fct_claim` / `fct_lookup`, no new logic, only fixed definitions.

## Why this and not the alternative

A dbt metrics layer or `dbt_metrics` package would be the "proper" answer and is out of
scope per the brief (no BI/semantic layer). A plain table is queryable by anything,
readable in the repo, and editable live.

## Cost

Two more tables to keep in sync with the facts. A pre-aggregated grain answers its
questions fast and nothing else, an ad-hoc cut still goes to `fct_claim`.

## Non-goals

No new business logic; anything not derivable from the facts today belongs in a different
spec. No dashboards.

## Acceptance

- [ ] `sum(revenue)` in `gld_partner_performance` equals `sum(net_revenue)` in `fct_claim`
- [ ] `gld_conversion_funnel` lookup count equals `count(*)` in `fct_lookup`
- [ ] `analysis/queries/01_partner_value.sql` rewrites to a `select *` with a filter
- [ ] `task test` passes

## Outcome

*Not yet implemented.*
