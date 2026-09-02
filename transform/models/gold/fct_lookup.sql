-- GOLD fact. GRAIN: one row per lookup, the top of the conversion funnel.
--
-- Kept as a separate fact rather than folded into fct_claim because 76% of
-- lookups never convert. Merging them would force every revenue query to filter,
-- and would turn "conversion rate" into a question about NULLs instead of a ratio
-- of two counts. The two facts conform on dim_drug, dim_partner and dim_date.
select
    l.lookup_id,
    l.claim_id,
    l.ndc,
    l.partner,
    l.channel,
    l.looked_up_date                                    as date_day,
    l.looked_up_at,

    l.flag_converted                                    as converted,
    c.claim_id is not null                              as converted_to_valid_claim,
    l.flag_unknown_partner,

    -- Claim-side context, null for the 76% that never convert.
    c.chain,
    c.is_reverted,
    c.net_revenue,
    c.net_pbm_fee,
    c.net_white_lodge_margin,
    date_diff('minute', l.looked_up_at, c.filled_at)    as minutes_to_fill
from {{ ref('slv_lookups') }} l
left join {{ ref('fct_claim') }} c on l.claim_id = c.claim_id
