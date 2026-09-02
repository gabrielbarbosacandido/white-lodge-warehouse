-- Lookup -> claim -> reversal, by partner and channel.
-- Lookups that never convert are pure cost; reversals are revenue that arrived
-- and then left. Both are margin levers that do not require repricing anything.
select
    partner,
    channel,
    count(*)                                                            as lookups,
    sum(converted_to_valid_claim::int)                                  as claims,
    round(100.0 * sum(converted_to_valid_claim::int) / count(*), 2)     as conversion_pct,
    sum(coalesce(is_reverted, false)::int)                              as reverted,
    round(100.0 * sum(coalesce(is_reverted, false)::int)
          / nullif(sum(converted_to_valid_claim::int), 0), 2)           as revert_rate_pct,
    round(sum(coalesce(net_white_lodge_margin, 0)), 2)                  as margin
from gold.fct_lookup
group by 1, 2
order by lookups desc;
