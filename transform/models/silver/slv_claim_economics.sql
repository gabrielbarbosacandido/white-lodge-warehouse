-- SILVER, step 3 of 3: the money, and the reversal.
--
-- Per the brief's simplified model:
--   pharmacy keeps  price - cost - pbm_fee
--   partner earns   their share of pbm_fee (flat cents OR percentage)
--   we keep         the rest of the pbm_fee
--
-- Attribution: a claim's partner is the partner of the lookup that converted into
-- it. Verified 1:1 in this data; the qualify keeps it 1:1 if that ever changes.
-- 933 claims have no converting lookup, so no partner and no payout.
--
-- Reversal is resolved here so gold never has to re-derive it. Every measure is
-- emitted twice: gross (what was submitted) and net (zero if reverted).
with converting_lookup as (
    select claim_id, partner, channel, looked_up_at
    from {{ ref('slv_lookups') }}
    where claim_id is not null
    qualify row_number() over (partition by claim_id order by looked_up_at) = 1
),

joined as (
    select
        c.*,
        l.partner,
        l.channel,
        l.looked_up_at,
        p.fee_cents,
        p.fee_percentage,
        p.fee_type,
        r.revert_id,
        r.reverted_at
    from {{ ref('slv_claim_costs') }} c
    left join converting_lookup l on c.claim_id = l.claim_id
    left join {{ ref('slv_partners') }} p on l.partner = p.partner
    left join {{ ref('slv_reverts') }} r on c.claim_id = r.claim_id
),

priced as (
    select
        *,
        revert_id is not null                                as is_reverted,
        nadac_per_unit * quantity                            as drug_cost,
        price / nullif(quantity, 0)                          as unit_price,
        {{ partner_fee_share('pbm_fee', 'fee_cents', 'fee_percentage') }}
                                                             as partner_fee
    from joined
)

select
    claim_id,
    npi,
    chain,
    ndc,
    partner,
    channel,
    fee_type,
    filled_at,
    filled_date,
    looked_up_at,
    is_reverted,
    reverted_at,
    date_diff('hour', filled_at, reverted_at)               as hours_to_revert,

    -- Gross: what was submitted.
    price,
    quantity,
    unit_price,
    pbm_fee,
    drug_cost,
    nadac_per_unit,
    cost_as_of_date,
    partner_fee,
    pbm_fee - partner_fee                                   as white_lodge_margin,
    price - drug_cost - pbm_fee                             as pharmacy_margin,

    is_generic,
    flag_cost_unavailable,
    flag_fee_exceeds_price
from priced
