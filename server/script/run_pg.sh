#!/bin/bash

# BASH "strict" mode
# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="run_pg"
CURR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function usage {
    echo "Usage: $0"
    exit 1
}

if [[ $# -ne 0 ]]; then
    usage
    exit 1
fi

echo -e "Starting PG server.  Please wait ...\n"
exec /usr/lib/postgresql/10/bin/postgres -D /var/lib/postgresql/10/main \
	-c listen_addresses=* \
	-c config_file=/etc/postgresql/10/main/postgresql.conf \
	-c log_connections=yes \
	-c log_statement=ddl

