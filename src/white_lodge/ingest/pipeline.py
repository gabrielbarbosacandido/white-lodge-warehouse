"""dlt pipeline: land every source into the DuckDB `landing` schema.

`landing` is the pre-medallion drop zone: source-shaped, untyped, plus the
quarantine tables. dbt owns bronze -> silver -> gold from there.

Ingestion's only jobs are: read from a path, validate structurally, and land the
result with lineage. All modelling happens downstream in dbt.
"""

from __future__ import annotations

import dlt

from white_lodge.ingest.sources import events, reference
from white_lodge.ingest.sources.nadac import nadac
from white_lodge.settings import Settings


def build_pipeline(settings: Settings) -> dlt.Pipeline:
    settings.duckdb_path.parent.mkdir(parents=True, exist_ok=True)
    return dlt.pipeline(
        pipeline_name="white_lodge",
        destination=dlt.destinations.duckdb(str(settings.duckdb_path)),
        dataset_name="landing",
        progress="log",
    )


def run(settings: Settings, only: set[str] | None = None):
    """Run the ingestion. `only` restricts to named sources, e.g. {"nadac"}."""
    resources = {
        "claims": lambda: events.claims(settings.claims_dir),
        "reverts": lambda: events.reverts(settings.reverts_dir),
        "lookups": lambda: events.lookups(settings.lookups_dir),
        "pharmacies": lambda: reference.pharmacies(settings.pharmacies_dir),
        "partners": lambda: reference.partners(settings.partners_dir),
        "nadac": lambda: nadac(settings.nadac_url, settings.nadac_dir),
    }
    selected = [factory() for name, factory in resources.items() if not only or name in only]
    return build_pipeline(settings).run(selected)
