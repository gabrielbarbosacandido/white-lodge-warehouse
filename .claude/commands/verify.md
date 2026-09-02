---
description: Prove the warehouse is sound from a cold start
---

Verify this project end to end and report what you actually observed.

1. `task clean && task build`, cold rebuild. Report the wall time.
2. `task test`, report pass counts for both pytest and dbt.
3. Query the row flow and confirm it reconciles exactly:
   landing → bronze → (exclusions) → silver → gold.
4. Confirm `sum(net_revenue)` in `gold.fct_claim` is unchanged from the previous run,
   or explain precisely what changed it.
5. Spot-check the fee split: flat partners paid in cents not dollars; the zero-fee partner
   earns nothing but still has claims; percentage partners take their stated share.

Report failures with the actual output. Do not claim a step passed that you did not run.
