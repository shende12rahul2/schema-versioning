#!/bin/bash
# Runs ONCE, the first time the lab container starts.
# 1. Creates the lab users.  2. Loads the legacy scripts into LEGACY_DEV.
set -e
CONN="//localhost:1521/FREEPDB1"

echo "### Lab setup: creating users"
sqlplus -s -L / as sysdba @/opt/lab/sql/create_users.sql "${LAB_PASSWORD}"

echo "### Lab setup: loading db/legacy into LEGACY_DEV"
cd /opt/legacy
sqlplus -s -L "legacy_dev/${LAB_PASSWORD}@${CONN}" @install_all.sql

echo "### Lab setup: done"
