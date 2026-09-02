-- SILVER: the snapshot series, one row per (ndc, as_of_date).
-- Verified unique in source; the qualify keeps it true if CMS ever republishes
-- a week. Still a series, not a single cost, that collapse happens next.
select
    ndc,
    ndc_description,
    nadac_per_unit,
    effective_date,
    as_of_date,
    pricing_unit,
    rate_setting_class,
    is_generic,
    is_otc
from {{ ref('brz_nadac') }}
qualify row_number() over (
    partition by ndc, as_of_date order by effective_date desc
) = 1
