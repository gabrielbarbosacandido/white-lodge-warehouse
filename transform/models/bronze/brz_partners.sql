-- BRONZE: partner commercial terms.
-- fee_cents = 0 (Airflow Rx) is a real term. Every flag below is written against
-- NULL-ness, never truthiness, so a zero-fee partner is never mistaken for a
-- partner with no terms.
select
    partner,
    fee_cents::double                   as fee_cents,
    fee_percentage::double              as fee_percentage,

    (fee_cents is not null and fee_percentage is not null)
                                        as flag_both_fee_terms,
    (fee_cents is null and fee_percentage is null)
                                        as flag_no_fee_terms,

    _dlt_load_id                        as load_id
from {{ source('landing', 'partners') }}
