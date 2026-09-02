-- SILVER, step 1 of 3: resolve claim identity and scope.
--
-- Two exclusions happen here, and only here:
--
-- 1. DUPLICATE CLAIM IDS. 140 ids repeat across 281 rows and no colliding group
--    is an exact copy: the same UUID carries a different npi, ndc, price and date.
--    That makes this disambiguation, not deduplication, and there is no evidence
--    to disambiguate with. Choosing one arbitrarily would misattribute revenue
--    AND route any revert on that id to the wrong claim. Default refuses to guess.
--    Override: --vars 'duplicate_claim_policy: keep_earliest'
--
-- 2. OUT-OF-SCOPE PHARMACIES. "We only care about events for pharmacies that
--    exist in the pharmacy dataset". An inner join is that filter. 502 claims
--    across 4 unknown NPIs drop out.
--
-- `flag_fee_exceeds_price` is carried forward, NOT filtered: it is economically
-- impossible but structurally valid, so it stays countable in gold.
with resolved as (
    select
        *,
        row_number() over (
            partition by claim_id order by filled_at, source_file
        ) as id_rank
    from {{ ref('brz_claims') }}
),

deduplicated as (
    select * from resolved
    {% if var('duplicate_claim_policy') == 'quarantine_all' %}
    where claim_id_occurrences = 1
    {% elif var('duplicate_claim_policy') == 'keep_earliest' %}
    where id_rank = 1
    {% else %}
    {{ exceptions.raise_compiler_error(
        "duplicate_claim_policy must be 'quarantine_all' or 'keep_earliest'") }}
    {% endif %}
)

select
    c.claim_id,
    c.npi,
    p.chain,
    c.ndc,
    c.price,
    c.quantity,
    c.pbm_fee,
    c.filled_at,
    c.filled_date,
    c.flag_fee_exceeds_price,
    c.source_file
from deduplicated c
join {{ ref('slv_pharmacies') }} p using (npi)
