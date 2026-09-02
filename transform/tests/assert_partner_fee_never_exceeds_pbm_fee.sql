-- The fee split must never pay a partner more than we collected.
-- This is what catches a cents/dollars mixup in partner_fee_share.
select claim_id, pbm_fee, partner_fee
from {{ ref('fct_claim') }}
where partner_fee > pbm_fee + 0.0001
