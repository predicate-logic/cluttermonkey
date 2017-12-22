#!/bin/bash
# Run script in a docker container
# Builds docker container if not pre-built.

function usage {
    echo "Usage: $0 (-s | -b[i])"
    echo "  -b     Run Bash, leave shell open."
    exit 1
}

# script install directory
DOCKER_IMAGE="clutter"
SCRIPT_NAME="get"

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
            ;;
        b)
            CMD=${CMD_BASH}
            INTERACTIVE="--interactive --tty"
            ;;
        i)
            CMD=${CMD_BASH}
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
echo "Running: '$CMD'"

# run docker container, pass env vars
docker run --rm ${INTERACTIVE} \
    --name clutter_${SCRIPT_NAME} \
    -h clutter_${SCRIPT_NAME} \
    --dns=8.8.8.8 \
    --volume $CURR_PATH:/$SCRIPT_NAME \
    --link clutter_server \
    $DOCKER_IMAGE:$SCRIPT_NAME $CMD 2>&1
