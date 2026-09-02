-- 3 of 49 NDCs are deliberately absent from NADAC (~1.4% of claims). If coverage
-- drops far below that, the join broke rather than the data being sparse.
select
    count(*)                                                as claims,
    sum(flag_cost_unavailable::int)                         as uncosted,
    round(100.0 * sum(flag_cost_unavailable::int) / count(*), 2) as uncosted_pct
from {{ ref('fct_claim') }}
having 100.0 * sum(flag_cost_unavailable::int) / count(*) > 10.0
