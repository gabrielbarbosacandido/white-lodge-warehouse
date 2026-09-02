---
description: Draft a new spec in specs/proposals from a one-line idea
---

Draft a spec for: $ARGUMENTS

Follow the workflow in @specs/README.md and the shape of @specs/TEMPLATE.md.

Before writing:

1. Read @CLAUDE.md for the layering rules and the verified facts about this data.
2. Check @specs/decisions/, if this reopens a settled choice, say which one and write the
   spec as superseding it rather than ignoring it.
3. **Verify any number you cite** by querying the warehouse (`task query -- "..."`). Do not
   put a figure in a spec you have not run.

Then write `specs/proposals/NNNN-<slug>.md`, numbering from the highest existing spec.

Requirements:
- Name exactly one medallion layer. If it seems to need two, the design is wrong, say so.
- The **Cost** section must be real. A spec with no cost has not been thought through.
- Acceptance criteria must be checkable by a command, not by opinion.
- Keep it under a page.

Finally, add the row to the Proposals table in @specs/README.md. Do not implement anything.
