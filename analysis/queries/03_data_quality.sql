-- What did we drop, and why? Every exclusion is queryable, not buried in a log.
-- Ingestion-time rejects (bronze) and model-time exclusions (silver) in one view.
select 'rejected at ingest' as stage, stream, reject_reason as reason, count(*) as records
from bronze.brz_rejects
group by 1, 2, 3

union all

select 'excluded in silver', 'claims', 'duplicate_claim_id', count(*)
from bronze.brz_claims where claim_id_occurrences > 1

union all

select 'excluded in silver', 'claims', 'pharmacy_not_in_reference', count(*)
from bronze.brz_claims b
left join silver.slv_pharmacies p using (npi)
where p.npi is null and b.claim_id_occurrences = 1

order by stage, records desc;
