# 0008. SCD-2 partner terms so claims price at contemporaneous rates

- **Status:** proposed
- **Layer:** silver
- **Size:** M

## Problem

`slv_partners` is fully reloaded each run, so the warehouse only knows *today's* commercial
terms. Every claim is priced at current terms regardless of when it was filled. If Flink Rx
moved from 50% to 80% in May, every March claim is now silently repriced at 80% and the
margin trend is fiction.

The sample data cannot exercise this, one version of each partner, which is exactly why
it will go unnoticed until it matters.

## Decision

Make partner terms SCD-2 via a dbt snapshot: `valid_from`, `valid_to`, `is_current`. The
fee join in `slv_claim_economics` becomes a range join on `filled_date between valid_from
and valid_to`. `dim_partner` keeps a current-only view for reference lookups.

## Why this and not the alternative

The brief scopes SCD-2 machinery out and says a README paragraph scores the same. That
paragraph exists, this spec proposes the build only if fee terms are expected to change,
which is the one condition that makes it load-bearing rather than ceremony.

Event-sourcing the partner file (append every version, derive validity) was considered and
rejected: dbt snapshots already do this and are one file.

## Cost

Snapshots introduce state, the snapshot table must persist across runs, which breaks the
"full reload each run, always reproducible from source" property the project currently has.
That is a real loss and the main argument against doing it now.

## Non-goals

Not applying SCD-2 to pharmacies. Chain reassignment is rare and the same pattern applies
if it ever matters.

## Acceptance

- [ ] A partner whose terms change mid-window prices pre-change claims at old terms
- [ ] `assert_gold_measures_reconcile` still holds
- [ ] Row count of `fct_claim` is unchanged, the range join must not fan out
- [ ] README's "reference-data history" section updated from proposal to implementation

## Outcome

*Not yet implemented. Deliberately deferred: the sample data cannot demonstrate the benefit,
and the reproducibility cost is real.*
