-- A partner has one of fee_cents / fee_percentage, never both, never neither.
-- Written against NULL-ness, not truthiness: Airflow Rx's fee_cents = 0 is real.
select partner
from {{ ref('dim_partner') }}
where (fee_cents is not null and fee_percentage is not null)
   or (fee_cents is null and fee_percentage is null)
