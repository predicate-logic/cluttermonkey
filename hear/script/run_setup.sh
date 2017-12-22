#!/bin/bash

# BASH "strict" mode
# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="hear"
CURR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# open up PG to accept all connections
echo "host  all  all 172.0.0.0/8 trust" >>  /etc/postgresql/10/main/pg_hba.conf

echo "Configuring Clutter PG instance.  Please wait ..."
/usr/bin/pg_ctlcluster 10 main start -o "-c listen_addresses=*" -o "-c log_connections=yes" -o "-c log_statement=ddl"
/usr/bin/createdb clutter
psql -U postgres --quiet -f /$SCRIPT_NAME/script/create.sql clutter

# run script to collect SSEvents
cd ${SCRIPT_NAME}
echo "Running SSEvents listener." 1>&2
exec python -m hear.cli stream
