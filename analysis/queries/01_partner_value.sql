-- Dale Cooper: for a chain, who is our most valuable partner vs the runner-up?
-- Change the chain in the WHERE clause. "Valuable" is deliberately split into
-- revenue, fee collected, and margin retained, they rank differently.
select
    partner,
    count(*)                                    as claims,
    sum(net_fills)                              as fills,
    round(sum(net_revenue), 2)                  as revenue,
    round(sum(net_pbm_fee), 2)                  as pbm_fee_collected,
    round(sum(net_partner_fee), 2)              as paid_to_partner,
    round(sum(net_white_lodge_margin), 2)       as margin_retained,
    round(100.0 * sum(net_partner_fee) / nullif(sum(net_pbm_fee), 0), 1) as pct_of_fee_paid_out,
    round(100.0 * sum(is_reverted::int) / count(*), 2)                   as revert_rate_pct
from gold.fct_claim
where chain = 'meridian'
group by 1
order by margin_retained desc;
