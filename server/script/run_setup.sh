#!/bin/bash

# BASH "strict" mode
# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="server"
CURR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function usage {
    echo "Usage: $0"
    exit 1
}

if [[ $# -ne 0 ]]; then
    usage
    exit 1
fi

echo -e "Configuring Clutter PG instance.  Please wait ...\n"
/usr/bin/pg_ctlcluster 10 main start
/usr/bin/createdb clutter
psql -U postgres -f /$SCRIPT_NAME/script/create.sql clutter
/usr/bin/pg_ctlcluster 10 main stop
exec /$SCRIPT_NAME/script/run_pg.sh
