-- What would we retain if the percentage partners moved to a flat term?
--
-- Backs the largest claim in the margin answer. The comparison works because
-- pbm_fee is uncorrelated with price (r = 0.07) and averages 7.34 per claim, so
-- a percentage term costs far more than a flat one at the same volume.
--
-- A flat term is paid per completed fill, hence net_fills rather than count(*):
-- a reverted claim pays no partner fee.
select
    f.partner,
    p.fee_type,
    coalesce(p.fee_cents, p.fee_percentage)                     as term,
    sum(f.net_fills)                                            as fills,
    round(sum(f.net_pbm_fee), 2)                                as fee_collected,
    round(sum(f.net_partner_fee), 2)                            as paid_now,
    round(sum(f.net_white_lodge_margin), 2)                     as retained_now,
    round(sum(f.net_fills) * 1.00, 2)                           as paid_if_flat_100c,
    round(sum(f.net_pbm_fee) - sum(f.net_fills) * 1.00, 2)      as retained_if_flat_100c,
    round(sum(f.net_partner_fee) - sum(f.net_fills) * 1.00, 2)  as gain
from gold.fct_claim f
join gold.dim_partner p using (partner)
group by 1, 2, 3
order by gain desc;
