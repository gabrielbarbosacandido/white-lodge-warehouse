-- BRONZE: the NADAC weekly snapshot series, typed. All 34 snapshots retained:
-- collapsing them to one cost per drug is a silver decision, not a bronze one.
select
    ndc,
    ndc_description,
    nadac_per_unit::double              as nadac_per_unit,
    effective_date::date                as effective_date,
    as_of_date::date                    as as_of_date,
    pricing_unit,
    rate_setting_class,
    rate_setting_class = 'G'            as is_generic,
    is_otc,
    _dlt_load_id                        as load_id
from {{ source('landing', 'nadac') }}
where as_of_date is not null
