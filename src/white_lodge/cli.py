"""`wl`, the pipeline entrypoint. Every source is a directory path."""

from __future__ import annotations

from pathlib import Path
from typing import Optional

import typer

from white_lodge.settings import Settings

app = typer.Typer(add_completion=False, help="White Lodge Savings pipeline.")


@app.callback()
def main() -> None:
    """Keep subcommands addressable even when only one exists."""


@app.command()
def ingest(
    claims_dir: Optional[Path] = typer.Option(None, help="Directory of claim JSON files."),
    reverts_dir: Optional[Path] = typer.Option(None, help="Directory of revert JSON files."),
    lookups_dir: Optional[Path] = typer.Option(None, help="Directory of lookup JSON files."),
    pharmacies_dir: Optional[Path] = typer.Option(None, help="Directory of pharmacy CSVs."),
    partners_dir: Optional[Path] = typer.Option(None, help="Directory of partner CSVs."),
    nadac_url: Optional[str] = typer.Option(None, help="CMS NADAC CSV URL."),
    duckdb_path: Optional[Path] = typer.Option(None, help="Warehouse file to write."),
    only: Optional[str] = typer.Option(None, help="Comma-separated subset, e.g. 'nadac'."),
):
    """Land raw sources into DuckDB via dlt."""
    overrides = {
        k: v
        for k, v in dict(
            claims_dir=claims_dir,
            reverts_dir=reverts_dir,
            lookups_dir=lookups_dir,
            pharmacies_dir=pharmacies_dir,
            partners_dir=partners_dir,
            nadac_url=nadac_url,
            duckdb_path=duckdb_path,
        ).items()
        if v is not None
    }
    settings = Settings(**overrides)

    from white_lodge.ingest.pipeline import run

    info = run(settings, only={s.strip() for s in only.split(",")} if only else None)
    typer.echo(info)


if __name__ == "__main__":
    app()
