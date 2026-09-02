"""Tests on the logic that is actually tricky, not coverage for its own sake."""

import pytest

from white_lodge.contracts import validate_claim, validate_lookup, validate_revert

VALID_CLAIM = {
    "id": "c1", "npi": "1234567890", "ndc": "00093721410",
    "price": 42.5, "quantity": 30.0, "pbm_fee": 3.25,
    "timestamp": "2026-06-02T02:09:22",
}


def test_valid_claim_is_renamed_and_typed():
    clean, reason = validate_claim(VALID_CLAIM)
    assert reason is None
    assert clean["claim_id"] == "c1"
    assert clean["price"] == 42.5
    assert clean["filled_at"].year == 2026


@pytest.mark.parametrize(
    "override, expected",
    [
        ({"price": "one hundred"}, "non_numeric:price"),
        ({"quantity": "thirty"}, "non_numeric:quantity"),
        ({"timestamp": "not-a-date"}, "unparseable_timestamp"),
        ({"timestamp": "2026-13-45T99:99:99"}, "unparseable_timestamp"),
        ({"timestamp": ""}, "unparseable_timestamp"),
        ({"price": -1.0}, "negative_price"),
        ({"quantity": 0}, "non_positive_quantity"),
        ({"ndc": None}, "missing_required_field:ndc"),
        ({"npi": None}, "missing_required_field:npi"),
    ],
)
def test_malformed_claims_are_quarantined_with_a_reason(override, expected):
    clean, reason = validate_claim({**VALID_CLAIM, **override})
    assert clean is None
    assert reason == expected


def test_word_numerals_are_never_coerced():
    """Guessing that 'one hundred' means 100 would invent revenue. Reject instead."""
    clean, _ = validate_claim({**VALID_CLAIM, "price": "one hundred"})
    assert clean is None


def test_numeric_strings_are_accepted():
    """A quoted number is a formatting quirk, not corruption."""
    clean, reason = validate_claim({**VALID_CLAIM, "price": "42.5"})
    assert reason is None and clean["price"] == 42.5


def test_lookup_claim_id_may_be_null():
    """Most lookups never convert, a null claim_id is the normal case, not an error."""
    clean, reason = validate_lookup({
        "id": "l1", "claim_id": None, "ndc": "00093721410",
        "partner": "Kafka Rx", "channel": "website",
        "timestamp": "2026-06-06T09:11:08",
    })
    assert reason is None and clean["claim_id"] is None


def test_revert_without_claim_id_is_useless():
    clean, reason = validate_revert({"id": "r1", "claim_id": None, "timestamp": "2026-06-15T05:15:53"})
    assert clean is None and reason == "missing_required_field:claim_id"
