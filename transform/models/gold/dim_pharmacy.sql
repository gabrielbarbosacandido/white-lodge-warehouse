-- GOLD dimension. GRAIN: one row per NPI. Natural key: npi.
-- Fully reloaded each run; see the README on SCD-2 at scale.
select
    npi,
    chain
from {{ ref('slv_pharmacies') }}
