-- BRONZE: every record ingestion refused, in one place, with its raw payload.
-- "How much did we drop and why" is a single query against this model.
{% set streams = ['claims', 'reverts', 'lookups'] %}

{% for stream in streams %}
select
    '{{ stream }}'      as stream,
    reject_reason,
    raw_payload,
    _source_file        as source_file,
    _dlt_load_id        as load_id
from {{ source('landing', stream ~ '_rejects') }}
{% if not loop.last %}union all{% endif %}
{% endfor %}
