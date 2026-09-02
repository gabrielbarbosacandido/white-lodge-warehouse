# CLAUDE.md, working agreement for this repository

Context for AI assistants and contributors. Read this before proposing changes.

## What this is

A data warehouse over pharmacy events for White Lodge Savings, a fictional PBM, built for a
take-home assignment.

- [CHALLENGE.md](CHALLENGE.md), the brief, unmodified
- [README.md](README.md), what the project does, the tools used, how to run it

The assignment is assessed on the data model and the reasoning behind it, not on platform
engineering. The repository is opened and modified during a live session, which drives every
convention below.

## Operating rules

1. **Optimise for modifiability, not for scale.** A model that can be opened and edited under
   time pressure is preferred over a more sophisticated one. A change that makes the
   repository harder to read is the wrong change.
2. **Never remove a row silently.** Every excluded record is either quarantined with a
   recorded reason in `bronze.brz_rejects`, or excluded by a documented rule in silver that a
   test reconciles.
3. **Expose decisions as configuration, not as buried code.** Modelling choices that could
   defensibly go another way are dbt `vars`.
4. **Comment the reasoning, not the mechanics.** The SQL states what it does. Comments exist
   to record the trade-off that someone will question.
5. **Do not add a tool for a problem this project does not have.** Out of scope per the
   brief: orchestrators, streaming frameworks, cloud infrastructure, CI/CD, BI as a
   deliverable, incremental loads, performance work.

## Architecture

```
landing -> bronze -> silver -> gold
 (dlt)     (dbt)     (dbt)     (dbt)
```

| Zone | Responsibility | May remove rows |
|---|---|---|
| `landing` | dlt drop zone: source-shaped, untyped, plus quarantine tables | Only to quarantine, with a reason |
| `bronze` | Type, rename, attach lineage, flag quality issues | No, enforced by test |
| `silver` | Clean, conform, resolve, enrich. Business rules | Yes, every exclusion documented |
| `gold` | Star schema for analysts and agents | No, presentation only |

The operating rule: **bronze flags, silver decides, gold presents.**

- A new quality signal becomes a `flag_*` boolean column in **bronze**
- A new business rule that removes or resolves rows goes in **silver**, with a reconciliation
  test
- A new way to slice existing data goes in **gold**, usually a dimension rather than a new
  fact

## Where to make a change

| To change | Edit |
|---|---|
| What counts as a malformed record | `src/white_lodge/contracts.py` |
| How a source is read | `src/white_lodge/ingest/sources/` |
| The duplicate claim or NADAC cost policy | `transform/dbt_project.yml` vars |
| The fee split | `transform/macros/partner_fee_share.sql` |
| What analysts query | `transform/models/gold/` |
| A command | `Taskfile.yaml` |

## Commands

`task` lists all 28. Two lanes run the same pipeline:

| Step | Host | Docker |
|---|---|---|
| Everything | `task all` | `task docker:all` |
| Ingestion | `task ingest` | `task docker:ingest` |
| Transformation | `task transform` | `task docker:transform` |

Also: `task up` starts the containers without running a pipeline, `task query` opens a
read-only shell, `task test` runs both suites, `task refresh` rebuilds while Superset is
running.

Run `task build` after changing a model, and `task test` before reporting completion.

`task ingest` and `task transform` hold a lock. DuckDB accepts one writer, and concurrent
runs corrupt dlt load packages. Do not bypass the lock, and do not open the warehouse in
write mode manually. To test a failure path, copy the file and point `WL_DUCKDB_PATH` at the
copy.

The `pipeline` compose service sits behind a profile, so `task up` cannot start it.

## Verified facts about this data

Figures a proposal must remain consistent with. All verified by query.

- 42,251 claims land. 41,510 reach gold. 281 excluded as duplicate IDs, 460 as out-of-scope
  pharmacies. 2,343 records quarantined at ingestion
- 140 claim IDs collide, and no colliding group is an exact copy. Different NPI, NDC, price
  and date under the same UUID. This is disambiguation, not deduplication
- `fee_cents` is denominated in cents. `pbm_fee` is denominated in dollars. One partner has
  `fee_cents = 0`, which is an actual term and must not be treated as null
- NADAC is 34 weekly snapshots, not one cost per drug. Three of 49 NDC codes are absent
  entirely: `77777000303`, `88888000202`, `99999000101`
- 76 percent of lookups never convert. That is the reason for two fact tables
- One claim is reversed twice. The first reversal applies
- DuckDB accepts one writer. Superset holding a live connection blocks a dbt write
  intermittently, which is harder to diagnose than a consistent failure. Use `task refresh`
- NADAC can land with zero rows while every other test passes, because the ASOF join returns
  nulls rather than failing. `assert_nadac_snapshots_loaded` exists because this occurred

## Conventions

- **Naming:** `brz_`, `slv_`, `dim_`, `fct_`. A boolean describing a data problem is
  `flag_*`. A boolean describing a business state is `is_*`
- **Measures:** every fact measure exists in gross and `net_*` form, where net is reversal
  aware. Business totals use `net_*`. New measures follow the same pair
- **Materialisation:** bronze and silver are views, which keeps the pipeline inexpensive and
  always current. Gold is tables, which keeps queries fast
- **Tests:** added where logic can produce an incorrect result: fee arithmetic, reversal
  handling, malformed records, layer reconciliation. Not for coverage
- **Python:** typed, functions rather than classes where a function is sufficient, ruff line
  length 100

## Proposing changes

Non-trivial changes get a written spec before code. See [specs/README.md](specs/README.md).

Decisions already taken are in [specs/decisions/](specs/decisions/). Read the relevant one
before reopening a choice. To disagree with a decision, write a new spec that supersedes it
rather than editing the record.

Open proposals are in [specs/proposals/](specs/proposals/).

## Behaviours that resemble defects but are intentional

- Reverted claims retain rows in `fct_claim`. The reversal rate is a metric
- `gold.fct_claim.partner` is null for 933 claims. Those claims had no converting lookup
- `bronze.brz_claims` contains duplicate `claim_id` values. Bronze does not filter
- `pbm_fee` exceeds `price` on 110 claims. Economically impossible but structurally valid,
  so it is flagged rather than removed
- Revenue totals are large, approximately 200 million. The sample data is synthetic
