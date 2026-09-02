-- LAYER CONTRACT: bronze flags, it never filters. Its row count must equal the
-- landing table exactly.
select 'claims' as stream
from (select count(*) as n from {{ ref('brz_claims') }}) b,
     (select count(*) as n from {{ source('landing', 'claims') }}) l
where b.n <> l.n
union all
select 'lookups'
from (select count(*) as n from {{ ref('brz_lookups') }}) b,
     (select count(*) as n from {{ source('landing', 'lookups') }}) l
where b.n <> l.n
