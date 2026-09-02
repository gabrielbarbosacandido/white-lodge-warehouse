# Specs

Spec-driven development for this repo: **a short written spec before non-trivial code.**

## Why

This project gets opened live and changed on the spot. The bottleneck in that conversation
is never typing speed. It is *reconstructing why the thing is the way it is*. A spec is
the artifact that makes a change reviewable before it exists, and reconstructable after.

It also means an AI assistant can be handed "implement `specs/proposals/0007`" instead of a
paragraph of prose, and produce something that fits the repo's grain.

## Two kinds of document

| Folder | What it holds | Mutable? |
|---|---|---|
| [`decisions/`](decisions/) | Choices already made and implemented. The record of *why*. | No. Supersede, do not edit |
| [`proposals/`](proposals/) | Work not yet done. Ready to pick up. | Yes, until accepted |

A proposal that gets built moves to `decisions/` with its outcome filled in. A decision
that gets reversed stays put and gains a `Superseded by:` line. The reasoning is worth
more than the tidiness.

## The loop

```
1. Write   →  copy TEMPLATE.md into proposals/NNNN-slug.md
2. Agree   →  the Decision + Non-goals sections are the contract
3. Build   →  implement; the spec's acceptance checks are the definition of done
4. Record  →  move to decisions/, fill in Outcome
```

**Skip the spec** for typo fixes, a new saved query, a comment, or a test on existing
behaviour. **Write one** for anything that changes a grain, moves a rule between medallion
layers, adds a source, changes a number a business answer depends on, or adds a dependency.

## Writing a good one

- **State the tradeoff you are accepting.** A spec with no cost section is a spec that has
  not been thought through.
- **Name the layer.** Every change belongs to exactly one of landing/bronze/silver/gold.
  If it seems to belong to two, the design is wrong.
- **Make acceptance checkable.** "Queries are faster" is not acceptance. "`task test`
  passes and `assert_bronze_reconciles_to_silver` still holds" is.
- **Keep it under a page.** If it needs more, it is more than one spec.

Background reading before writing a spec: [CLAUDE.md](../CLAUDE.md) carries the layering
contract and the verified data facts, and [README.md](../README.md) describes the
architecture and the tools.

## Index

**Decisions**

| # | Title | Layer |
|---|---|---|
| [0001](decisions/0001-medallion-layering.md) | Medallion layering with bronze-flags/silver-decides | all |
| [0002](decisions/0002-quarantine-duplicate-claim-ids.md) | Quarantine colliding claim ids rather than pick one | silver |
| [0003](decisions/0003-nadac-as-of-fill.md) | Price claims at the NADAC snapshot as-of the fill date | silver |
| [0004](decisions/0004-dlt-dbt-duckdb.md) | dlt + dbt + DuckDB, with the tool boundary at bronze | all |
| [0005](decisions/0005-gross-and-net-measures.md) | Every measure exists as gross and net | gold |
| [0006](decisions/0006-two-facts-not-one.md) | Two facts (claim, lookup) rather than one wide table | gold |

**Proposals**

| # | Title | Layer | Size |
|---|---|---|---|
| [0007](proposals/0007-gold-metric-marts.md) | Gold metric marts so a metric has one definition | gold | S |
| [0008](proposals/0008-scd2-partner-terms.md) | SCD-2 partner terms so claims price at contemporaneous rates | silver | M |
| [0009](proposals/0009-incremental-facts.md) | Incremental facts with a late-arriving-revert window | gold | M |
| [0010](proposals/0010-reconciliation-model.md) | A revenue reconciliation model that proves nothing is lost | gold | S |
