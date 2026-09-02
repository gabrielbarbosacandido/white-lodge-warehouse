-- The NADAC source is remote and cached, so it can silently land empty, a failed
-- pull, a truncated cache, an ingest that skipped it. Every downstream cost then
-- becomes NULL, the ASOF join still succeeds, and every other test still passes.
-- This is the test that makes that loud.
--
-- Expectation: the 2026 file carries ~34 weekly snapshots over ~1.03M rows.
-- Fails if fewer than 10 snapshots are present or the table is empty.
select
    count(*)                        as rows_loaded,
    count(distinct as_of_date)      as snapshots
from {{ ref('brz_nadac') }}
having count(*) = 0
    or count(distinct as_of_date) < 10
