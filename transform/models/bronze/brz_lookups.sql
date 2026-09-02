-- BRONZE: typed lookups. The raw channel string is preserved alongside the
-- normalised one, bronze never destroys a source value, it only adds.
select
    lookup_id,
    claim_id,
    ndc,
    partner,
    channel                             as channel_raw,
    case
        when nullif(trim(channel), '') is null then 'unknown'
        else lower(trim(channel))
    end                                 as channel,
    claim_id is not null                as flag_converted,
    nullif(trim(channel), '') is null   as flag_missing_channel,

    looked_up_at::timestamp             as looked_up_at,
    looked_up_at::date                  as looked_up_date,

    _source_file                        as source_file,
    _dlt_load_id                        as load_id
from {{ source('landing', 'lookups') }}
