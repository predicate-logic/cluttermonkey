#!/bin/bash
# Run script in a docker container
# Builds docker container if not pre-built.

function usage {
    echo "Usage: $0 (-b)"
    echo "  -r     Run PG server and listen for SSEvents."
    echo "  -s     Stop PG server and SSEvents listener."
    echo "  -b     Run Bash, leave shell open."
    echo "  -h     These help instructions."
}

# script install directory
DOCKER_IMAGE="cluttermonkey"
SCRIPT_NAME="hear"

# path of this/self script.
CURR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_PATH="$CURR_PATH/$SCRIPT_NAME"

# default values
PYENV_VERSION="${PYENV_VERSION:-3.5.1}"

INTERACTIVE=""
DETACH=""
while getopts "hsrBb" opt; do
   case $opt in
      h) usage
         exit 0
         ;;
      r)
         running=$(docker inspect -f {{.State.Running}} ${DOCKER_IMAGE}_${SCRIPT_NAME} > /dev/null 2>&1)
         if [[ "$running" == "true" ]]; then
             echo "Container already running.  Skipping start."
             docker ps | grep ${DOCKER_IMAGE}_${SCRIPT_NAME}
             exit 1
         fi
         echo "Container running: $running"
         echo "Setting up Dockerized PostgreSQL.  Server will start after setup."
         sleep 1
         CMD="/$SCRIPT_NAME/script/run_setup.sh"
         DETACH=""
         ;;
      s)
         echo "Stopping container: ${DOCKER_IMAGE}_${SCRIPT_NAME}"
         docker stop ${DOCKER_IMAGE}_${SCRIPT_NAME}
         exit $? 
         ;;
      B)
         running=$(docker inspect -f {{.State.Running}} ${DOCKER_IMAGE}_${SCRIPT_NAME} > /dev/null 2>&1)
         if [[ "$running" == "true" ]]; then
             echo "Container already running.  Use -b flag to connect to running container."
             docker ps | grep ${DOCKER_IMAGE}_${SCRIPT_NAME}
             exit 1
         fi
         echo "Container running: $running"
         echo "Starting container with BASH shell: ${DOCKER_IMAGE}_${SCRIPT_NAME}"
         CMD="/bin/bash"
         INTERACTIVE="--interactive --tty"
         DETACH=""
         ;;
      b)
         echo "Starting BASH shell in running container: ${DOCKER_IMAGE}_${SCRIPT_NAME}"
         docker exec --interactive --tty ${DOCKER_IMAGE}_${SCRIPT_NAME} /bin/bash
         exit $? 
         ;;
      *)
        echo "Invalid options passed.  Exiting."
        usage
        exit 1
   esac
done

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

echo
echo "=="
echo "SQLPad query/viz access:"
echo "In a browser got to http://localhost:3000 and login as: admin@cluttermonkey.com / password"
echo "==="
echo "Once logged in try the following URL's or click on the chart options for each defined query."
echo "Top Editors: http://localhost:3000/query-chart/gT8IVTheryUHI8nO"
echo "Edit Types: http://localhost:3000/query-chart/Dq1RSaZyPWG1gGwC"
echo "Edits By Minute: http://localhost:3000/query-chart/vlJqTigQJzeYiDEi"
echo "==="
echo "Refreshing the browser will pull the latest data from the data store."
sleep 2

# run docker container, pass env vars
docker run ${DETACH} ${INTERACTIVE} --rm \
        --name ${DOCKER_IMAGE}_${SCRIPT_NAME} \
        -h ${DOCKER_IMAGE}_${SCRIPT_NAME} \
        --dns=8.8.8.8 \
        -p 54321:5432 \
        -p 3000:3000 \
        --volume $CURR_PATH:/$SCRIPT_NAME \
        $DOCKER_IMAGE:$SCRIPT_NAME $CMD 2>&1 

if [ ! -z "$DETACH" ]; then
        echo "Docker container detached, but running in the background."
fi

