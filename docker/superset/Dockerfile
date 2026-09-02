# Superset + duckdb-engine.
#
# duckdb-engine is a SQLAlchemy dialect over the *Python* duckdb package, so we
# pin the exact version the pipeline writes with (1.5.5) and file-format
# compatibility is guaranteed by construction. This is why Superset works here
# and Metabase does not. Metabase's community DuckDB driver is JDBC, last
# released in 2024 against DuckDB 0.10, and cannot open a 1.5 file at all.
FROM apache/superset:4.1.4

USER root
RUN pip install --no-cache-dir "duckdb==1.5.5" "duckdb-engine>=0.15"
COPY docker/superset/superset_config.py /app/pythonpath/superset_config.py
COPY docker/superset/bootstrap.sh /app/bootstrap.sh
RUN chmod +x /app/bootstrap.sh

USER superset
ENV SUPERSET_CONFIG_PATH=/app/pythonpath/superset_config.py
ENTRYPOINT ["/app/bootstrap.sh"]
