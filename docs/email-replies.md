# Draft replies for the submission email

The brief requires both answers **in the body of the submission email**, not as an
attachment and not in the README. This file is a working draft to paste from. Every figure
is reproducible against the warehouse; the query for each is noted in italics.

---

## Reply to Dale Cooper, "partner mix before renegotiations"

Hi Dale,

I looked at **meridian**, our largest chain by both volume and retained margin: 9
pharmacies, 11,170 claims, 51.4M in revenue and 50,452 in margin retained.

**Your most valuable partner there is Kafka Rx, and it is not close.**

| Partner | Terms | Claims | Revenue | Fee collected | Paid to partner | **We retain** |
|---|---|---|---|---|---|---|
| **Kafka Rx** | flat, 100 cents | 3,253 | 16.6M | 22,529 | 3,051 | **19,478** |
| Hudi Rx | 50% of fee | 3,046 | 11.6M | 20,225 | 10,112 | **10,112** |
| Druid Rx | 20% of fee | 1,524 | 7.4M | 10,011 | 2,002 | 8,009 |
| Iceberg Rx | flat, 20 cents | 904 | 4.6M | 6,179 | 170 | 6,009 |
| Airflow Rx | flat, 0 cents | 412 | 1.2M | 2,629 | 0 | 2,629 |
| Flink Rx | 80% of fee | 1,764 | 8.9M | 12,328 | 9,862 | 2,466 |

**Kafka versus Hudi, the second best.** The gap is not volume. Hudi sends us 94% of Kafka's
claim count (3,046 against 3,253) and the two collect a similar fee, 20,225 against 22,529.
The gap is entirely commercial terms. Kafka's flat 100 cents costs us 13.5% of the fee we
collect. Hudi's 50% share costs us, unsurprisingly, 50%. So near identical volume produces
19,478 from Kafka and 10,112 from Hudi, a 1.9x difference.

Per claim, that is 5.99 retained from Kafka against 3.32 from Hudi.

**Three things I would take into the renegotiation:**

1. **Flink's terms cost us the most, Hudi is the bigger relationship.** Moving each to
   Kafka's flat term on meridian alone is worth 8,204 from Flink and 7,356 from Hudi, so
   Flink is the larger single recovery despite sending only 1,764 claims against Hudi's
   3,046. The trade-off is exposure: Hudi delivers 73% more volume, so if a renegotiation
   costs us the relationship, losing Hudi hurts considerably more. I would open with Flink
   for that reason, not only because the number is bigger.

2. **Iceberg is the most efficient relationship we have.** At a flat 20 cents it costs 2.7%
   of the fee, and returns 6.65 per claim, the best of any partner. It is small at 904
   claims. If there is volume to be bought anywhere, it is here, and the terms mean the
   volume arrives almost entirely as margin.

3. **Hudi and Druid also revert more.** Hudi at 9.52% and Druid at 10.5% against Kafka's
   6.21%. A reverted claim earns nothing and still costs us to process, so their effective
   value is slightly below what the table shows.

One caveat worth stating: a lookup is not attached to a pharmacy until it converts, so
conversion rate cannot be split by chain. The conversion figures I have are per partner
across the whole book, where Kafka converts 53.5% of what it sends against Hudi's 19.6%.
That reinforces the ranking rather than changing it.

Happy to run any of this a different way.

*Queries: `analysis/queries/01_partner_value.sql` with `chain = 'meridian'`, and
`02_conversion_funnel.sql`.*

---

## Reply to Gordon Cole, "margin"

Hi Gordon,

The most useful thing I found is not a lever, it is a fact about how we earn.

**Our fee is unrelated to the price of the drug.** The correlation between `pbm_fee` and
`price` is 0.07, effectively zero, and the average fee is flat at about 7.34 per claim
across every price band. We are paid per transaction, not per dollar dispensed.

That has an immediate consequence:

| | Claims | Revenue | Margin we retain |
|---|---|---|---|
| Generic | 32,965 (80%) | 4.6M | **141,946 (78%)** |
| Brand | 7,974 (20%) | 195.8M | 40,354 (22%) |

Brand drugs move 195.8M of revenue and produce a fifth of our margin. **Any strategy aimed
at revenue or at high-value scripts will not move our margin.** Volume of fills will.

With that established, here is where I would look, largest first.

### 1. Partner fee terms, worth roughly +36%

This is by far the biggest number in the data. We collect 284,542 in fees and pay out
35.2% of it. But the terms are wildly inconsistent:

| Partner | Terms | Fills | Paid out | Effective cost |
|---|---|---|---|---|
| Kafka Rx | flat 100c | 9,965 | 9,965 | 13.7% |
| Iceberg Rx | flat 20c | 3,319 | 664 | 2.7% |
| Airflow Rx | flat 0c | 1,566 | 0 | 0% |
| Druid Rx | 20% | 5,314 | 7,799 | 20% |
| Hudi Rx | 50% | 10,209 | 37,619 | 50% |
| Flink Rx | 80% | 7,500 | 44,144 | 80% |

Because the average fee is 7.34, a percentage term is far more expensive than a flat one.
Flink's 80% costs 5.87 per claim where Kafka's flat term costs 1.00.

If the three percentage partners moved to Kafka's flat 100 cents, we would retain **66,539
more**, taking total margin from 184,351 to 250,890, a **36% increase**. Hudi alone accounts
for 27,410 of that and Flink for 36,644.

That is a negotiating position rather than a forecast. Partners may refuse, and volume may
fall if they do. But it sizes the prize, and it says the conversation to have first is with
Flink and Hudi.

### 2. Channel mix, worth a large but uncertain amount

Integration and website behave like two different businesses:

| Channel | Lookups | Conversion | Margin per lookup | Reversal rate |
|---|---|---|---|---|
| Integration | 48,610 | **45.2%** | **2.01** | 5.4% |
| Website | 126,371 | 14.7% | 0.63 | 8.2% |

Website carries 72% of our lookup volume and converts at a third of the rate. It also
reverts half again as often. Every point of website conversion is worth about 5,400 in
margin at current terms.

I would not assume the gap is pure execution: someone using a partner integration is
probably further along in deciding to fill than someone browsing a price on a website. But
the gap is large enough that even closing a quarter of it is worth more than most other
things on this list.

There is also a small tail worth cleaning up: 854 lookups arrive on `fax`, `phone`, `app`
or with no channel at all, and **none of them ever convert**. That is either dead traffic
or a tracking defect, and it is cheap to find out which.

### 3. Reversals, worth about 13,000

6.66% of claims are reversed, costing us 13,255 in margin that we booked and then gave
back, 6.7% of gross. Reversals concentrate: Airflow 8.69%, Druid 8.21% and Hudi 8.06%
against Flink's 5.05%. Website reverts at 8.16% against integration's 5.39%.

This is the smallest of the three levers, but it is the one that requires no renegotiation
with anyone.

### What I would measure

Two north-star metrics, both defined per transaction rather than per dollar, because that
is how we actually earn:

- **Retained margin per fill**, currently 4.76. This catches a bad terms change immediately.
- **Margin per lookup**, currently 1.01. This moves with conversion and with terms at the
  same time, so it is the single number that tells us whether a partner relationship is
  improving.

### What I could not tell you

Our cost benchmark is NADAC, which is a public acquisition-cost reference, not what we
actually pay. 226 fills, 0.59%, are priced below NADAC cost, and I cannot tell from this
data whether that is a pricing error or a rebate arrangement that NADAC does not see. If
there is a real acquisition-cost feed, it would sharpen every margin figure above.

Happy to dig into any of these.

*Queries: `analysis/queries/05_fee_term_scenarios.sql` for the fee term comparison,
`02_conversion_funnel.sql` for the channel figures, and `04_margin_by_drug.sql` for the
generic and brand split.*
