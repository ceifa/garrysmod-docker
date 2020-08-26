[![Garry's mod containers](https://i.imgur.com/QEGv6GM.png "Garry's mod containers")][docker-hub-repo]

# Garry's Mod server
Run a Garry's Mod server easily inside a docker container

## Supported tags
* `latest` - the most recent production-ready image, based on `debian`
* `debian` - a gmod server based on debian
* `debian-root` - same as `debian` but executed as root user
* `debian-post` - same as `debian` but the server is installed with the container starting
* `debian-post-root` - same as `debian-post` but executed as root user
* `ubuntu` - a gmod server based on ubuntu

## Features

* Run a server under a linux non-root user
* Run a server under an anonymous steam user
* Run server commands normally
* Installed CSS content
* Check and update server automatically
* Production and development build

## Documentation

### Ports
The container uses the following ports:
* `:27015 TCP/UDP` as the game transmission, pings and RCON port
* `:27005 UDP` as the client port

You can read more about these ports on the [official srcds documentation][srcds-connectivity].

### Environment variables

**`PRODUCTION`**

Set if the server should be opened in production mode. This will make hot reload modifications to lua files not working. Possible values are `0`(default) or `1`.

**`HOSTNAME`**

Set the server name on startup.

**`MAXPLAYERS`**

Set the maximum players allowed to join the server. Default is `16`.

**`GAMEMODE`**

Set the server gamemode on startup. Default is `sandbox`.

**`MAP`**

Set the map gamemode on startup. Default is `gm_construct`.

**`PORT`**

Set the server port on container. Default is `27015`.

**`GSLT`**

Set the server GSLT credential to be used.

**`ARGS`**

Set any other custom args you want to pass to srcds runner.

### Directory structure
It's not the full directory tree, I just put the ones I thought most important

```cs
📦 /home/gmod // The server root
|__📁steamcmd // Steam cmd, used to update the server when needed
|__📁mounts // All third party games should be installed here
|  |  |__📁cstrike // Counter strike: Source comes installed as default
|__📁server
|  |__📁garrysmod
|  |  |__📁addons // Put your addons here
|  |  |__📁gamemodes // Put your gamemodes here
|  |  |__📁data
|  |  |__📁cfg
|  |  |  |__⚙️server.cfg
|  |  |__📁lua
|  |  |__📁cfg
|  |  |__💾sv.db
|  |__📃srcds_run
|__📃start.sh // Script to start the server
|__📃update.txt // Steam cmd script to run before start the server
```

## Examples

This will start a simple server in a container named `gmod-server`:
```sh
docker run \
    -p 27015:27015/udp \
    -p 27015:27015 \
    -p 27005:27005/udp \
    --name gmod-server \
    -it \
    ceifa/gmod-server
```

This will start a server with host workshop collection pointing to [382793424][workshop-example] named `gmod-server`:
```sh
docker run \
    -p 27015:27015/udp \
    -p 27015:27015 \
    -p 27005:27005/udp \
    -e ARGS="+host_workshop_collection 382793424" \
    -it \
    ceifa/gmod-server
```

This will start a server named `my server` in production mode pointing to a local addons with a custom gamemode:
```sh
docker run \
    -p 27015:27015/udp \
    -p 27015:27015 \
    -p 27005:27005/udp \
    -v $PWD/addons:/home/gmod/server/garrysmod/addons \
    -v $PWD/gamemodes:/home/gmod/server/garrysmod/gamemodes \
    -e HOSTNAME="my server" \
    -e PRODUCTION=1 \
    -e GAMEMODE=darkrp \
    -it \
    ceifa/gmod-server
```

You can create a new docker image using this image as base too:

```dockerfile
FROM ceifa/gmod-server:latest

COPY ./deathrun-addons /home/gmod/server/garrysmod/addons

ENV NAME="Lory | Deathrun ~ Have fun!"
ENV ARGS="+host_workshop_collection 382793424"
ENV MAP="deathrun_atomic_warfare"
ENV GAMEMODE="deathrun"
ENV MAXPLAYERS="24"
```

More examples can be found at [my real use case github repository][lory-repo].

## Health Check

This image contains a health check to continually ensure the server is online. That can be observed from the STATUS column of docker ps

```sh
CONTAINER ID        IMAGE                    COMMAND                 CREATED             STATUS                    PORTS                                                                                     NAMES
e9c073a4b262        ceifa/gmod-server        "/home/gmod/start.sh"   21 minutes ago      Up 21 minutes (healthy)   0.0.0.0:27005->27005/tcp, 27005/udp, 0.0.0.0:27015->27015/tcp, 0.0.0.0:27015->27015/udp   distracted_cerf
```

You can also query the container's health in a script friendly way:

```sh
> docker container inspect -f "{{.State.Health.Status}}" e9c073a4b262
healthy
```

## License

This image is under the [MIT license](licence).

[docker-hub-repo]: https://hub.docker.com/r/ceifa/gmod-server "Docker hub repository"

[srcds-connectivity]: https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity "Valve srcds connectivity documentation"

[workshop-example]: https://steamcommunity.com/sharedfiles/filedetails/?id=382793424 "Steam workshop collection"

[lory-repo]: https://github.com/ceifa/lory-gmod-servers "Lory server repository"

[licence]: https://github.com/ceifa/gmod-server-docker/blob/master/LICENSE "Licence of use"
