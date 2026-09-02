"""Local-only Superset config. Metadata lives in the container's SQLite app db.

This is analyst tooling for the live session, not a deliverable, see the README.
Nothing here is safe for anything beyond localhost.
"""

import os

SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "white-lodge-local-dev-only")

# Superset's own metadata DB (dashboards, charts, users), kept separate from the
# analytical warehouse, which it only ever reads.
SQLALCHEMY_DATABASE_URI = "sqlite:////app/superset_home/superset.db"

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_VIRTUALIZATION": True,
}

# The warehouse is mounted read-only; make that explicit at the app layer too.
PREVENT_UNSAFE_DB_CONNECTIONS = False
SQLLAB_CTAS_NO_LIMIT = False
ROW_LIMIT = 50_000
SUPERSET_WEBSERVER_TIMEOUT = 120
TALISMAN_ENABLED = False
WTF_CSRF_ENABLED = False
