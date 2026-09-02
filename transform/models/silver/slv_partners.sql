-- SILVER: conformed partner terms.
select
    partner,
    fee_cents,
    fee_percentage,
    case
        when fee_cents is not null      then 'flat'
        when fee_percentage is not null then 'percentage'
        else 'undefined'
    end                                 as fee_type
from {{ ref('brz_partners') }}
where not flag_both_fee_terms
