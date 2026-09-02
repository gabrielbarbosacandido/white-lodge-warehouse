-- BRONZE: typed reverts, with the multiple-revert case flagged, not resolved.
select
    revert_id,
    claim_id,
    reverted_at::timestamp              as reverted_at,
    reverted_at::date                   as reverted_date,

    count(*) over (partition by claim_id) > 1
                                        as flag_multiple_reverts,
    row_number() over (partition by claim_id order by reverted_at, revert_id)
                                        as revert_sequence,

    _source_file                        as source_file,
    _dlt_load_id                        as load_id
from {{ source('landing', 'reverts') }}
