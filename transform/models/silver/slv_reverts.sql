-- SILVER: one effective reversal per claim.
-- One claim carries two reverts; the first wins, because a second cannot
-- re-reverse an already-void fill. 18 reverts point at claims that do not exist
-- (or were excluded upstream) and are dropped by the inner join, a reversal of
-- nothing is not a reversal.
select
    r.revert_id,
    r.claim_id,
    r.reverted_at,
    r.reverted_date,
    r.flag_multiple_reverts
from {{ ref('brz_reverts') }} r
join {{ ref('slv_claims') }} c using (claim_id)
where r.revert_sequence = 1
