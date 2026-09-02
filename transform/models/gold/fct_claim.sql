-- GOLD fact. GRAIN: one row per valid, in-scope claim.
--
-- Foreign keys are natural keys (npi, ndc, partner, date_day) rather than
-- surrogates: the source identifiers are already stable and globally unique, so
-- surrogate keys would add a lookup hop and buy nothing at this scale. The
-- tradeoff is that a key change in the source would ripple. Noted and accepted.
--
-- READ THIS BEFORE SUMMING. Reverted claims KEEP their row, because reversal rate
-- is a metric worth measuring. Every measure exists twice: gross (what was
-- submitted) and net_* (zero when reverted). SUM THE net_* COLUMNS. That is what
-- "treated as if the fill never happened" means, and a dbt test asserts it.
select
    -- Degenerate + foreign keys
    e.claim_id,
    e.npi,
    e.ndc,
    e.partner,
    e.filled_date                                       as date_day,
    e.chain,
    e.channel,
    e.fee_type,

    -- Event timing
    e.filled_at,
    e.is_reverted,
    e.reverted_at,
    e.hours_to_revert,
    e.looked_up_at,
    date_diff('minute', e.looked_up_at, e.filled_at)    as minutes_lookup_to_fill,

    -- Gross measures
    e.price,
    e.quantity,
    e.unit_price,
    e.pbm_fee,
    e.partner_fee,
    e.white_lodge_margin,
    e.pharmacy_margin,
    e.drug_cost,
    e.nadac_per_unit,

    -- Net measures: additive, reversal-aware. Sum these.
    if(not e.is_reverted, e.price, 0)                   as net_revenue,
    if(not e.is_reverted, e.quantity, 0)                as net_quantity,
    if(not e.is_reverted, e.pbm_fee, 0)                 as net_pbm_fee,
    if(not e.is_reverted, e.partner_fee, 0)             as net_partner_fee,
    if(not e.is_reverted, e.white_lodge_margin, 0)      as net_white_lodge_margin,
    if(not e.is_reverted, e.pharmacy_margin, 0)         as net_pharmacy_margin,
    if(not e.is_reverted, e.drug_cost, 0)               as net_drug_cost,
    if(not e.is_reverted, 1, 0)                         as net_fills,

    -- Quality context, carried not filtered
    e.is_generic,
    e.cost_as_of_date,
    e.flag_cost_unavailable,
    e.flag_fee_exceeds_price
from {{ ref('slv_claim_economics') }} e
