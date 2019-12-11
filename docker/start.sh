docker stop gmod-server -t 0
docker rm gmod-server
docker run --net=host -it --name gmod-server ceifa/gmod-server