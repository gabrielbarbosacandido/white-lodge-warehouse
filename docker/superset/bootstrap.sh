#!/usr/bin/env bash
# Idempotent first-run setup, then hand off to Superset's own server script.
set -euo pipefail

ADMIN_USER="${SUPERSET_ADMIN_USERNAME:-admin}"
ADMIN_PASS="${SUPERSET_ADMIN_PASSWORD:-admin}"
WAREHOUSE_URI="duckdb:///${WL_DUCKDB_PATH:-/data/warehouse/white_lodge.duckdb}?access_mode=read_only"

superset db upgrade

superset fab create-admin \
  --username "$ADMIN_USER" --password "$ADMIN_PASS" \
  --firstname White --lastname Lodge --email admin@whitelodge.local || true

superset init

# Register the warehouse so the connection is already there on first login.
# Read-only, so Superset can never take DuckDB's single write lock from dbt.
python - <<PY
from superset.app import create_app

app = create_app()
with app.app_context():
    from superset import db
    from superset.models.core import Database

    uri = "${WAREHOUSE_URI}"
    existing = db.session.query(Database).filter_by(database_name="White Lodge").one_or_none()
    if existing is None:
        db.session.add(Database(database_name="White Lodge", sqlalchemy_uri=uri))
        print(f"registered White Lodge -> {uri}")
    else:
        existing.sqlalchemy_uri = uri
        print(f"updated White Lodge -> {uri}")
    db.session.commit()
PY

exec /usr/bin/run-server.sh
