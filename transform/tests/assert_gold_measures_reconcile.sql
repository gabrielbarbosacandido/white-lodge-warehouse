-- The fee identity: what we keep plus what the partner earns is the fee collected.
select claim_id
from {{ ref('fct_claim') }}
where abs((partner_fee + white_lodge_margin) - pbm_fee) > 0.0001
