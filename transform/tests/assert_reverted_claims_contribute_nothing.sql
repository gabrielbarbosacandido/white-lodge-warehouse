-- "Treated as if the fill never happened", asserted, not assumed.
select claim_id
from {{ ref('fct_claim') }}
where is_reverted
  and (net_revenue <> 0 or net_pbm_fee <> 0 or net_partner_fee <> 0 or net_fills <> 0)
