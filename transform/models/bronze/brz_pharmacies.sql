-- BRONZE: reference data, typed and trimmed only.
select
    npi,
    lower(trim(chain))                  as chain,
    _dlt_load_id                        as load_id
from {{ source('landing', 'pharmacies') }}
