[![Garry's mod containers](https://i.imgur.com/QEGv6GM.png "Garry's mod containers")][docker-hub-repo]

# Garry's Mod server
Run a Garry's Mod server easily inside a docker container

## Supported tags
* `latest` - the most recent production-ready image, based on `debian`
* `debian` - a gmod server based on debian
* `debian-x64` - (NOT STABLE YET) a gmod server based on debian but running on beta version of srcds for x64 bit CPUs
* `debian-root` - same as `debian` but executed as root user
* `debian-x64-root` - same as `debian-x64` but executed as root user
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

**`NAME`**

Set the server name (hostname) on startup.

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
|  |  |__📁data // Persisted as a volume (gamemode data + sv.db)
|  |  |__📁cfg
|  |  |  |__⚙️server.cfg
|  |  |__📁lua
|  |  |__💾sv.db // Symlinked into data/ so it survives container recreation
|  |__📃srcds_run
|__📃start.sh // Script to start the server
|__📃update.txt // Steam cmd script (generated on build, re-run for -autoupdate)
```

### Persistence
`/home/gmod/server/garrysmod/data` is declared as a volume, so gamemode data and
the `sv.db` database survive container recreation automatically. Bind-mount it to
keep the state on the host:

```sh
docker run \
    -p 27015:27015/udp \
    -p 27015:27015 \
    -p 27005:27005/udp \
    -v $PWD/data:/home/gmod/server/garrysmod/data \
    -it \
    ceifa/garrysmod:latest
```

`addons` and `gamemodes` are intentionally **not** volumes so they can be baked
into a derived image (see the `FROM ceifa/garrysmod` example below) or bind-mounted.

## Examples

This will start a simple server in a container named `gmod-server`:
```sh
docker run \
    -p 27015:27015/udp \
    -p 27015:27015 \
    -p 27005:27005/udp \
    --name gmod-server \
    -it \
    ceifa/garrysmod:latest
```

This will start a server with host workshop collection pointing to [382793424][workshop-example] named `gmod-server`:
```sh
docker run \
    -p 27015:27015/udp \
    -p 27015:27015 \
    -p 27005:27005/udp \
    -e ARGS="+host_workshop_collection 382793424" \
    -it \
    ceifa/garrysmod:latest
```

This will start a server named `my server` in production mode pointing to a local addons with a custom gamemode:
```sh
docker run \
    -p 27015:27015/udp \
    -p 27015:27015 \
    -p 27005:27005/udp \
    -v $PWD/addons:/home/gmod/server/garrysmod/addons \
    -v $PWD/gamemodes:/home/gmod/server/garrysmod/gamemodes \
    -e NAME="my server" \
    -e PRODUCTION=1 \
    -e GAMEMODE=darkrp \
    -it \
    ceifa/garrysmod:latest
```

You can create a new docker image using this image as base too:

```dockerfile
FROM ceifa/garrysmod:latest

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
e9c073a4b262        ceifa/garrysmod:latest        "/home/gmod/start.sh"   21 minutes ago      Up 21 minutes (healthy)   0.0.0.0:27005->27005/tcp, 27005/udp, 0.0.0.0:27015->27015/tcp, 0.0.0.0:27015->27015/udp   distracted_cerf
```

You can also query the container's health in a script friendly way:

```sh
> docker container inspect -f "{{.State.Health.Status}}" e9c073a4b262
healthy
```

## Performance

* **Use `--network host`** for the lowest latency. srcds is UDP-heavy and Docker's
  default userland NAT adds overhead; host networking avoids it (bind the ports on
  the host directly instead of using `-p`).
* **Prefer the `debian-x64` tag** on busy servers. The 64-bit srcds branch generally
  performs better and lifts the ~2 GB memory ceiling of the 32-bit build. It is still
  a Valve beta, so `latest` stays 32-bit.
* **Set `PRODUCTION=1`** for live servers, it disables Lua hot-reload and the `gdb`
  debug wrapper, both of which add overhead in the default development mode.

## Building

The four `debian*` tags are built from a single `Dockerfile` selected by build
args; `debian-post` and `ubuntu` have their own files. To build a variant locally:

```sh
# debian (default) / latest
docker build -f Dockerfile -t ceifa/garrysmod:debian .

# debian-root
docker build -f Dockerfile --build-arg FINAL_USER=root -t ceifa/garrysmod:debian-root .

# debian-x64
docker build -f Dockerfile \
    --build-arg STEAM_BETA="-beta x86-64" \
    --build-arg SRCDS_BINARY=srcds_run_x64 \
    -t ceifa/garrysmod:debian-x64 .

# debian-post / ubuntu
docker build -f debian-post.Dockerfile -t ceifa/garrysmod:debian-post .
docker build -f ubuntu.Dockerfile -t ceifa/garrysmod:ubuntu .
```

| Build arg | Default | Purpose |
| --- | --- | --- |
| `BASE_IMAGE` | `debian:trixie-slim` | Base image to build on |
| `STEAM_BETA` | _(empty)_ | Set to `-beta x86-64` for the x64 server branch |
| `SRCDS_BINARY` | `srcds_run` | `srcds_run_x64` for the x64 branch |
| `FINAL_USER` | `steam` | Set to `root` to run the container as root |

## License

This image is under the [MIT license](licence).

[docker-hub-repo]: https://hub.docker.com/r/ceifa/garrysmod "Docker hub repository"

[srcds-connectivity]: https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity "Valve srcds connectivity documentation"

[workshop-example]: https://steamcommunity.com/sharedfiles/filedetails/?id=382793424 "Steam workshop collection"

[lory-repo]: https://github.com/ceifa/lory-gmod-servers "Lory server repository"

[licence]: https://github.com/ceifa/garrysmod-docker/blob/master/LICENSE "Licence of use"
