# Pipeline image: dlt ingestion + dbt transforms. There is no warehouse server:
# DuckDB is embedded, so the "warehouse" is a file on the mounted volume.
FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /usr/local/bin/uv

WORKDIR /app
ENV UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/app/.venv \
    PATH="/app/.venv/bin:$PATH" \
    WL_DUCKDB_PATH=/app/data/warehouse/white_lodge.duckdb \
    DBT_PROFILES_DIR=/app/transform

# Dependencies first so source edits don't invalidate the layer.
COPY pyproject.toml uv.lock README.md ./
COPY src ./src
RUN uv sync --frozen --no-dev

COPY transform ./transform

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["wl ingest && dbt build --project-dir transform --profiles-dir transform"]
