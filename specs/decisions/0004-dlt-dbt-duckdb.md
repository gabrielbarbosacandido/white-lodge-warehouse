# 0004. dlt + dbt + DuckDB, with the tool boundary at bronze

- **Status:** accepted
- **Layer:** cross-cutting
- **Size:** M

## Problem

Ingestion and modelling are different problems, one fails on malformed bytes and changing
schemas, the other on wrong business logic. A single tool doing both blurs where a failure
came from.

## Decision

**dlt** owns landing (reading paths, structural validation, quarantine, lineage). **dbt**
owns bronze→gold. **DuckDB** is the warehouse, a file, not a service. The handoff is the
`landing` schema, and nothing reads it except bronze.

## Why this and not the alternative

Plain DuckDB `read_json_auto` over the directories would be shorter, and for the local JSON
files it does most of what dlt does. dlt earns its place on two things: the **NADAC pull**
(streaming a remote CSV with caching is exactly its shape) and giving quarantine a natural
home with load ids attached.

Postgres-in-Docker was rejected: nothing here needs concurrency, and DuckDB's `ASOF JOIN`
is doing real work in decision 0003.

## Cost

Two tools, two mental models, and a real operational sharp edge: **DuckDB allows many
readers or one writer, never both**. Superset holding a live connection blocks a dbt write
intermittently, since an idle pool releases the file, which is harder to diagnose than a
consistent failure. Mitigated by `task refresh`, not eliminated.

## Non-goals

No orchestrator. `task build` is the whole pipeline; the brief scopes Airflow out and
nothing here needs scheduling.

## Acceptance

- [x] `task build` runs the pipeline end to end from a deleted warehouse in ~60s
- [x] Nothing outside `models/bronze/` references `source('landing', …)`
- [x] The warehouse is a single portable file

## Outcome

Implemented. The boundary held up under the medallion restructure, bronze→gold was rebuilt
without touching ingestion at all, which is the payoff the split was chosen for.
