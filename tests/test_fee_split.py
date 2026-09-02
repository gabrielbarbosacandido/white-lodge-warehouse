"""The fee split, tested against the built warehouse.

fee_cents is in CENTS and pbm_fee in DOLLARS; a 100x error here is the easiest
mistake in this dataset and the hardest to spot in an aggregate.
"""

import duckdb
import pytest

from white_lodge.settings import Settings

SETTINGS = Settings()
pytestmark = pytest.mark.skipif(
    not SETTINGS.duckdb_path.exists(), reason="run `task build` first"
)


@pytest.fixture(scope="module")
def con():
    return duckdb.connect(str(SETTINGS.duckdb_path), read_only=True)


def test_flat_partner_is_paid_cents_not_dollars(con):
    """Kafka Rx is 100 cents = $1.00 per claim, never $100."""
    (fee,) = con.sql("""
        select distinct round(partner_fee, 4)
        from gold.fct_claim
        where partner = 'Kafka Rx' and pbm_fee >= 1.0
    """).fetchone()
    assert fee == 1.0


def test_zero_fee_partner_earns_nothing_but_still_exists(con):
    """Airflow Rx has fee_cents = 0, a real term. It must not be read as NULL."""
    claims, paid = con.sql("""
        select count(*), coalesce(sum(partner_fee), 0)
        from gold.fct_claim where partner = 'Airflow Rx'
    """).fetchone()
    assert claims > 0
    assert paid == 0.0


def test_percentage_partner_takes_its_stated_share(con):
    """Flink Rx is 80% of the PBM fee."""
    (ratio,) = con.sql("""
        select round(sum(partner_fee) / sum(pbm_fee), 3)
        from gold.fct_claim where partner = 'Flink Rx'
    """).fetchone()
    assert ratio == pytest.approx(0.80, abs=0.001)


def test_margin_and_partner_fee_reconstruct_the_pbm_fee(con):
    (mismatches,) = con.sql("""
        select count(*) from gold.fct_claim
        where abs((partner_fee + white_lodge_margin) - pbm_fee) > 0.0001
    """).fetchone()
    assert mismatches == 0
