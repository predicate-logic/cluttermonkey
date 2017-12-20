#!/bin/bash
# Run script in a docker container
# Builds docker container if not pre-built.

function usage {
    echo "Usage: $0 (-s | -b[i])"
    echo "  -s     Setup PG server."
    echo "  -b     Run Bash, leave shell open."
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

# script install directory
DOCKER_IMAGE="clutter"
SCRIPT_NAME="glisten"

# path of this/self script.
CURR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_PATH="$CURR_PATH/$SCRIPT_NAME"

# default values
PYENV_VERSION="${PYENV_VERSION:-3.5.1}"

# docker command "flavors"
CMD_BASH="/bin/bash"

INTERACTIVE=""
while getopts ":sbi" opt; do
    case $opt in
        s)
	    echo "Setting up Dockerized PostgreSQL.  This may take a few minutes ..."
            CMD=
            ;;
        b)
            CMD=${CMD_BASH}
            INTERACTIVE="--interactive --tty"
            ;;
        i)
            INTERACTIVE="--interactive --tty"
            ;;
    esac
done

if [ ! -z "$INTERACTIVE" ]; then
    echo "Interactive Docker shell."
else
    echo "Non-interactive Docker shell."
fi

# build docker image
echo "Building docker container.  Please wait ..."
docker build -t $DOCKER_IMAGE:$SCRIPT_NAME $CURR_PATH

if [ $? -ne 0 ]; then
    echo "WARNING: Docker build failed.  Check Docker build logs.  Exiting."
    exit -1
fi

echo "Script directory: $SCRIPT_PATH"
echo "Running as: $(id)"
echo "Running: $CMD"

# run docker container, pass env vars
#docker run ${PRIVILEGED} --rm --tty ${INTERACTIVE} \
docker run ${PRIVILEGED} --rm ${INTERACTIVE} \
    --name clutter_server \
    -e INTERACTIVE="${INTERACTIVE}" \
    -p 54321:5432 \
    -h clutter_server \
    --dns=8.8.8.8 \
    --volume $CURR_PATH:/$SCRIPT_NAME \
    $DOCKER_IMAGE:$SCRIPT_NAME $CMD 2>&1