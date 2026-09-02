-- SILVER: the authoritative pharmacy list. Membership here defines "in scope".
select npi, chain from {{ ref('brz_pharmacies') }}
