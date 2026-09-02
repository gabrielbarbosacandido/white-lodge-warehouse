-- GOLD dimension. GRAIN: one row per NDC observed in any event. Natural key: ndc.
-- Conformed across both facts. Attributes come from the most recent NADAC
-- snapshot naming the drug; an NDC with no NADAC row at all still gets a row here
-- so neither fact can silently lose claims on the join.
with observed as (
    select ndc from {{ ref('slv_claims') }}
    union
    select ndc from {{ ref('slv_lookups') }}
),

described as (
    select ndc, ndc_description, pricing_unit, rate_setting_class, is_generic, is_otc
    from {{ ref('slv_nadac') }}
    qualify row_number() over (partition by ndc order by as_of_date desc) = 1
)

select
    o.ndc,
    d.ndc_description,
    d.pricing_unit,
    d.rate_setting_class,
    d.is_generic,
    d.is_otc,
    d.ndc is null       as is_missing_from_nadac
from observed o
left join described d using (ndc)
