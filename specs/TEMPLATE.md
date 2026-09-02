# NNNN. <title>

- **Status:** proposed | accepted | superseded by NNNN
- **Layer:** landing | bronze | silver | gold | cross-cutting
- **Size:** S (<1h) | M (a few hours) | L (a day+)

## Problem

What is wrong or missing today. Be concrete, cite a row count, a query that cannot be
written, or a question the model cannot answer.

## Decision

What we will do, in two or three sentences. Written as a decision, not a discussion.

## Why this and not the alternative

The option(s) rejected, and what made this one win.

## Cost

What this makes worse. Every real decision has one, accuracy, coverage, runtime,
complexity, or a door it closes. A spec with an empty cost section is not finished.

## Non-goals

What this explicitly does not do, so scope cannot drift during implementation.

## Acceptance

Checkable statements. Aim for things a command can verify.

- [ ] `task build` succeeds
- [ ] `task test` passes, including layer reconciliation
- [ ] <the specific new behaviour, stated as a query and its expected result>

## Outcome

*Filled in after implementation: what actually happened, and anything learned that the
spec got wrong.*
