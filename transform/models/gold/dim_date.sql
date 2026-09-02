-- GOLD dimension. GRAIN: one row per calendar day spanning all observed events.
-- Built from the data's own range so it never silently ends before the facts do.
with bounds as (
    select
        least(min(filled_date), (select min(looked_up_date) from {{ ref('slv_lookups') }}))  as min_date,
        greatest(max(filled_date), (select max(looked_up_date) from {{ ref('slv_lookups') }})) as max_date
    from {{ ref('slv_claims') }}
)

select
    d::date                                     as date_day,
    year(d)                                     as year,
    quarter(d)                                  as quarter,
    month(d)                                    as month,
    monthname(d)                                as month_name,
    date_trunc('month', d)::date                as month_start,
    date_trunc('week', d)::date                 as week_start,
    dayofweek(d)                                as day_of_week,
    dayname(d)                                  as day_name,
    dayofweek(d) in (0, 6)                      as is_weekend
from bounds, unnest(generate_series(min_date, max_date, interval 1 day)) as t(d)
