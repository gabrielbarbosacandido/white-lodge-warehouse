-- SILVER: conformed lookups.
-- Lookups are NOT filtered to known partners: an unrecognised partner is a
-- reference-data gap, and dropping those rows would understate top-of-funnel
-- volume. It is surfaced as a flag instead.
select
    l.lookup_id,
    l.claim_id,
    l.ndc,
    l.partner,
    l.channel,
    l.channel_raw,
    l.looked_up_at,
    l.looked_up_date,
    l.flag_converted,
    p.partner is null       as flag_unknown_partner
from {{ ref('brz_lookups') }} l
left join {{ ref('slv_partners') }} p on l.partner = p.partner
