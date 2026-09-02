# 0002. Quarantine colliding claim ids rather than pick one

- **Status:** accepted
- **Layer:** silver
- **Size:** S

## Problem

140 claim ids appear more than once across 281 rows. **No colliding group is an exact
copy**: the same UUID carries a different NPI, NDC, price and fill date. `claim_id` is
also the join key for reverts and lookups.

## Decision

Exclude every row in a colliding group. Exposed as `duplicate_claim_policy`, default
`quarantine_all`, alternative `keep_earliest`.

## Why this and not the alternative

Standard dedup (`qualify row_number() = 1`) assumes the rows are copies and one is
redundant. Here they are not copies, so the operation is disambiguation with no evidence to
disambiguate on. Picking arbitrarily does two kinds of damage: it attributes revenue to the
wrong pharmacy and chain, and it routes any revert on that id to the wrong claim. The
second is silent and unrecoverable.

Refusing to guess is the position that can be defended without knowing which row is real.

## Cost

281 claims (0.66%) excluded from every total, including their revenue. If the collisions
are a replay artifact rather than corruption, this discards real business.

## Non-goals

No attempt to *resolve* collisions by matching against lookups or reverts. That heuristic
might work here and would not generalise.

## Acceptance

- [x] `bronze.brz_claims` retains all 281 rows, flagged `flag_duplicate_claim_id`
- [x] `silver.slv_claims` excludes them under the default policy
- [x] `--vars 'duplicate_claim_policy: keep_earliest'` builds and recovers 140 claims

## Outcome

Implemented. Because bronze keeps the flagged rows, the cost of the decision is itself
queryable, `select sum(price) from bronze.brz_claims where flag_duplicate_claim_id`
answers "what did this cost us?" without a rebuild.
