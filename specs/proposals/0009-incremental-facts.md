# 0009. Incremental facts with a late-arriving-revert window

- **Status:** proposed
- **Layer:** gold
- **Size:** M

## Problem

Gold facts are full-refresh tables. At this volume that is under a second, so this is not a
performance problem today. It is the 100x question the design session will ask.

The interesting part is not the incremental strategy. It is that **reverts arrive after
their claim**, sometimes days later. A naive `where filled_date > max(filled_date)`
incremental never revisits older claims, so a revert landing on a claim outside the window
is silently never applied, revenue stays booked on a fill that did not happen.

## Decision

Make `fct_claim` incremental on `filled_date` with a **lookback window** wide enough to
cover observed revert latency, plus a periodic full refresh. Derive the window from the
data (`max(hours_to_revert)`) rather than guessing, and assert it in a test that fails when
observed latency approaches the window.

## Why this and not the alternative

Merging on `claim_id` alone would handle late reverts but rewrites the whole table, which
is what incrementality was meant to avoid. A lookback window is the standard answer and its
failure mode is bounded and detectable.

## Cost

Correctness now depends on a tuned constant. If revert latency changes, the window silently
becomes wrong, which is why the test matters more than the window.

## Non-goals

No partitioning, clustering, or engine change. No incrementality for dimensions.

## Acceptance

- [ ] A revert landing on a claim inside the lookback is applied on the next run
- [ ] A test fails when observed `hours_to_revert` exceeds 80% of the window
- [ ] Full-refresh and incremental builds produce identical totals on the sample data

## Outcome

*Not yet implemented. Documented in the README's "what breaks at 100×" instead, per the
brief's guidance that reasoning scores the same as implementation here.*
