NAME="gmod-server"

# CHECK IF CONTAINER ALREADY EXISTS
if [ "$(docker ps -a -q -f name="${NAME}" --format '{{.Names}}')" == "${NAME}" ]; then
    # CHECK IF THE CONTAINER IS RUNNING
    if [ "$(docker ps -q -f name="${NAME}" --format '{{.Names}}')" == "${NAME}" ]; then
        docker stop "${NAME}" -t 0
    fi

    docker rm "${NAME}"
fi

# START CONTAINER
docker run \
    -p 27015:27015/udp \
    -p 27015:27015 \
    -p 27005:27005/udp \
    -it \
    --name gmod-server \
    ceifa/gmod-server

# WAIT FOR INPUT, USEFUL TO SEE UNEXPECTED ERRORS
read