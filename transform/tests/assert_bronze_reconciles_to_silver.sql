-- LAYER CONTRACT: every bronze claim is either in silver or explained by a
-- documented exclusion. If this fails, rows are vanishing somewhere unlabelled.
with bronze as (select count(*) as n from {{ ref('brz_claims') }}),
silver as (select count(*) as n from {{ ref('slv_claims') }}),
excluded_duplicates as (
    select count(*) as n from {{ ref('brz_claims') }}
    {% if var('duplicate_claim_policy') == 'quarantine_all' %}
    where claim_id_occurrences > 1
    {% else %}
    where false
    {% endif %}
),
excluded_out_of_scope as (
    select count(*) as n
    from {{ ref('brz_claims') }} b
    left join {{ ref('slv_pharmacies') }} p using (npi)
    where p.npi is null
      {% if var('duplicate_claim_policy') == 'quarantine_all' %}
      and b.claim_id_occurrences = 1
      {% endif %}
)
select
    bronze.n            as bronze_rows,
    silver.n            as silver_rows,
    excluded_duplicates.n,
    excluded_out_of_scope.n
from bronze, silver, excluded_duplicates, excluded_out_of_scope
where bronze.n <> silver.n + excluded_duplicates.n + excluded_out_of_scope.n
