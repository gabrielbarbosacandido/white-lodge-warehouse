-- Where the money actually is, by drug. Claims with no NADAC match are flagged
-- rather than dropped, so revenue always reconciles.
select
    d.ndc,
    d.ndc_description,
    d.is_generic,
    count(*)                                        as claims,
    round(sum(f.net_revenue), 2)                    as revenue,
    round(sum(f.net_drug_cost), 2)                  as est_drug_cost,
    round(sum(f.net_white_lodge_margin), 2)         as wl_margin,
    round(avg(f.unit_price - f.nadac_per_unit), 4)  as avg_unit_spread,
    sum(f.cost_is_estimated::int)                   as claims_without_nadac
from gold.fct_claim f
join gold.dim_drug d using (ndc)
group by 1, 2, 3
order by wl_margin desc
limit 25;
