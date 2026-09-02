"""Reversal handling: a reverted claim must contribute nothing to any total."""

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


def test_reverted_claims_are_kept_but_zeroed(con):
    reverted, revenue, fills = con.sql("""
        select count(*), coalesce(sum(net_revenue), 0), coalesce(sum(net_fills), 0)
        from gold.fct_claim where is_reverted
    """).fetchone()
    assert reverted > 0, "reversal rate is a metric, the rows must survive"
    assert revenue == 0 and fills == 0


def test_a_claim_reverted_twice_is_counted_once(con):
    """One claim in this data carries two reverts. It is still one reversal."""
    (dupes,) = con.sql("""
        select count(*) from (
            select claim_id from gold.fct_claim group by 1 having count(*) > 1
        )
    """).fetchone()
    assert dupes == 0


def test_reverts_never_predate_their_claim(con):
    (impossible,) = con.sql("""
        select count(*) from gold.fct_claim
        where is_reverted and reverted_at < filled_at
    """).fetchone()
    assert impossible == 0
