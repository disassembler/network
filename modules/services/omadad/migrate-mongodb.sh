#!/usr/bin/env bash
# Migrate Omada's MongoDB data from 6.0 to 8.x (via 7.0)
# Run this on optina as root BEFORE re-enabling the omadad service.
#
# The data at /var/lib/omadad/data/db is currently MongoDB 6.0 with FCV 6.0.
# MongoDB requires stepping through major versions: 6.0 -> 7.0 -> 8.0

set -euo pipefail

DBPATH="${1:-/var/lib/omadad/data/db}"
LOGFILE="$(dirname "$DBPATH")/../logs/mongod-migrate.log"
PORT=27217

mkdir -p "$(dirname "$LOGFILE")"
echo "Migrating MongoDB data at: $DBPATH"

echo "=== Step 1: Start MongoDB 7.0 against existing data ==="
mongod \
  --dbpath "$DBPATH" \
  --port "$PORT" \
  --bind_ip 127.0.0.1 \
  --logpath "$LOGFILE" \
  --logappend \
  --fork

echo "Waiting for mongod to be ready..."
for i in $(seq 1 30); do
  mongosh --port "$PORT" --eval "db.adminCommand({ping: 1})" --quiet && break
  sleep 1
done

echo "=== Step 2: Set featureCompatibilityVersion to 7.0 ==="
mongosh --port "$PORT" --eval \
  'db.adminCommand({setFeatureCompatibilityVersion: "7.0", confirm: true})'

echo "=== Step 3: Stop MongoDB 7.0 ==="
mongosh --port "$PORT" --eval \
  'db.adminCommand({shutdown: 1})' || true
# Give mongod a moment to shut down cleanly
sleep 3

echo ""
echo "Migration complete. Data is now at FCV 7.0 and ready for MongoDB 8.x."
echo "You can now enable services.omadad in optina's configuration."
