-- GOLD dimension. GRAIN: one row per partner. Natural key: partner.
-- fee_cents is in CENTS; fee_percentage is a percentage (50.0 = 50%).
select
    partner,
    fee_cents,
    fee_percentage,
    fee_type
from {{ ref('slv_partners') }}
