"""Source paths and warehouse location.

Every source is a directory path so the pipeline can be pointed at any drop
location, per the brief. CLI flags override env vars, which override defaults.
"""

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

NADAC_2026_URL = (
    "https://download.medicaid.gov/data/"
    "nadac-national-average-drug-acquisition-cost-08-26-2026.csv"
)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="WL_", env_file=".env", extra="ignore")

    claims_dir: Path = Path("data/landing/claims")
    reverts_dir: Path = Path("data/landing/reverts")
    lookups_dir: Path = Path("data/landing/lookups")
    pharmacies_dir: Path = Path("data/landing/pharmacies")
    partners_dir: Path = Path("data/landing/partners")

    nadac_url: str = NADAC_2026_URL
    nadac_dir: Path = Path("data/external/nadac")

    duckdb_path: Path = Path("data/warehouse/white_lodge.duckdb")
