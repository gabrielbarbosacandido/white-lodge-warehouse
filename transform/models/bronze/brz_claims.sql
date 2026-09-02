-- BRONZE: type, rename, stamp lineage, FLAG quality. Drops nothing.
-- Everything that survived ingestion appears here exactly once, so bronze is
-- the reconciliation point: silver's row count plus silver's exclusions must
-- equal this. Anomalies become boolean columns rather than deletions, because a
-- row you deleted in bronze is a row nobody can ever ask a question about.
select
    claim_id,
    npi,
    ndc,
    price::double                       as price,
    quantity::double                    as quantity,
    pbm_fee::double                     as pbm_fee,
    filled_at::timestamp                as filled_at,
    filled_at::date                     as filled_date,

    -- Quality flags, resolved in silver.
    pbm_fee > price                     as flag_fee_exceeds_price,
    count(*) over (partition by claim_id) > 1
                                        as flag_duplicate_claim_id,
    count(*) over (partition by claim_id)
                                        as claim_id_occurrences,

    _source_file                        as source_file,
    _dlt_load_id                        as load_id
from {{ source('landing', 'claims') }}
