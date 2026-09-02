---
description: Explain what a medallion layer does and what may change in it
---

Explain the `$ARGUMENTS` layer of this warehouse.

Read @CLAUDE.md for the layering contract, then inspect the actual models in
`transform/models/$ARGUMENTS/`.

Cover:
1. This layer's single job, and whether it is permitted to drop rows.
2. Each model in it, and the one decision each model owns.
3. The tests that enforce this layer's contract.
4. Actual row counts, query them with `task query`, do not recite them from docs.
5. What a change to this layer would look like, and what would make a change belong
   somewhere else instead.
