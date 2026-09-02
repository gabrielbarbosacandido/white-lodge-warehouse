-- SILVER, step 2 of 3: attach a cost to every claim.
--
-- THE NADAC DECISION. CMS publishes a rolling series of weekly snapshots, 34 of
-- them for 2026, covering Jan-Aug, against claims filled Mar-Jul. So "the cost of
-- this drug" is not a single number and picking a row is a modelling choice.
--
-- CHOICE (`as_of_fill`): the most recent snapshot published on or before the fill
-- date. DuckDB's ASOF JOIN expresses exactly that, in one pass.
-- WHY: it is the cost a buyer could actually have observed on the day of the fill.
-- WHAT IT COSTS: a claim filled before the first available snapshot gets no cost
-- rather than a value back-filled from the future. The alternative (`latest`)
-- prices everything at the newest snapshot. That is simpler and fully covered, but it
-- back-dates August prices onto March fills and erases cost drift across the
-- window, which is the exact trend a margin question is about.
--
-- 3 of 49 NDCs never appear in NADAC at all (77777000303, 88888000202,
-- 99999000101, planted). Those claims keep a NULL cost and a flag; they are not
-- dropped, because removing revenue to fix a cost gap is the wrong trade.
{% if var('nadac_cost_basis') == 'as_of_fill' %}

select
    c.*,
    n.nadac_per_unit,
    n.as_of_date                    as cost_as_of_date,
    n.pricing_unit,
    n.is_generic,
    n.nadac_per_unit is null        as flag_cost_unavailable
from {{ ref('slv_claims') }} c
asof left join {{ ref('slv_nadac') }} n
    on c.ndc = n.ndc
   and c.filled_date >= n.as_of_date

{% elif var('nadac_cost_basis') == 'latest' %}

with latest_snapshot as (
    select * from {{ ref('slv_nadac') }}
    qualify row_number() over (partition by ndc order by as_of_date desc) = 1
)
select
    c.*,
    n.nadac_per_unit,
    n.as_of_date                    as cost_as_of_date,
    n.pricing_unit,
    n.is_generic,
    n.nadac_per_unit is null        as flag_cost_unavailable
from {{ ref('slv_claims') }} c
left join latest_snapshot n on c.ndc = n.ndc

{% else %}
{{ exceptions.raise_compiler_error(
    "nadac_cost_basis must be 'as_of_fill' or 'latest'") }}
{% endif %}
