#!/usr/bin/env bash
set -euo pipefail

# Reads connection from db_connection.txt and applies each SQL file in this directory in lexicographic order.
# Each SQL statement should be idempotent where possible.
# Usage: ./apply_migrations.sh

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONN_FILE="${BASE_DIR%/migrations}/db_connection.txt"

if [ ! -f "${CONN_FILE}" ]; then
  echo "db_connection.txt not found at ${CONN_FILE}"
  echo "Ensure startup.sh has run and created the connection file."
  exit 1
fi

PSQL_CMD="$(cat "${CONN_FILE}")"
echo "Using connection: ${PSQL_CMD}"

# apply each migration one-by-one to conform with 'one statement at a time' execution rule when running via psql -c
# Here we call psql with -f for each file to ensure isolation per migration file
shopt -s nullglob
files=("${BASE_DIR}"/[0-9][0-9][0-9][0-9]_*.sql)

if [ ${#files[@]} -eq 0 ]; then
  echo "No migration files found in ${BASE_DIR}"
  exit 0
fi

for f in "${files[@]}"; do
  echo "Applying migration: $(basename "$f")"
  # Use psql -f to run the file, preserving statements. The connection command already includes psql and URL.
  ${PSQL_CMD} -v ON_ERROR_STOP=1 -f "$f"
  echo "✓ Applied $(basename "$f")"
done

echo "All migrations applied."
