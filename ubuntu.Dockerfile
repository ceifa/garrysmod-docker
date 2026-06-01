FROM ubuntu:26.04

LABEL maintainer="ceifa"
LABEL description="A structured Garry's Mod dedicated server under a ubuntu linux image"

ENV DEBIAN_FRONTEND=noninteractive
# Same i386 set as the Debian image (24.04+ kept the names through the t64 transition).
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get -y --no-install-recommends --no-install-suggests install \
        wget ca-certificates tar lib32gcc-s1 libgcc-s1 libcurl4-gnutls-dev:i386 \
        libcurl4:i386 libtinfo6:i386 lib32z1 lib32stdc++6 libncurses6:i386 \
        libcurl3-gnutls:i386 gdb libsdl2-2.0-0:i386 libfontconfig1 net-tools unzip \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

RUN useradd -d /home/gmod -m steam
USER steam
RUN mkdir /home/gmod/server && mkdir /home/gmod/steamcmd

RUN wget -P /home/gmod/steamcmd/ https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xzf /home/gmod/steamcmd/steamcmd_linux.tar.gz -C /home/gmod/steamcmd \
    && rm -rf /home/gmod/steamcmd/steamcmd_linux.tar.gz

COPY assets/update.txt /home/gmod/update.txt

# Retry: a fresh SteamCMD can fail the first app_update yet exit 0.
RUN for i in 1 2 3 4 5; do \
        /home/gmod/steamcmd/steamcmd.sh +runscript /home/gmod/update.txt +quit; \
        [ -f /home/gmod/server/srcds_run ] && break; \
        echo "GMod download attempt $i incomplete, retrying..."; \
    done; \
    [ -f /home/gmod/server/srcds_run ]

RUN for i in 1 2 3 4 5; do \
        /home/gmod/steamcmd/steamcmd.sh \
            +force_install_dir /home/gmod/temp \
            +login anonymous \
            +app_update 232330 validate \
            +quit; \
        [ -d /home/gmod/temp/cstrike ] && break; \
        echo "CSS download attempt $i incomplete, retrying..."; \
    done; \
    [ -d /home/gmod/temp/cstrike ] \
    && mkdir /home/gmod/mounts \
    && mv /home/gmod/temp/cstrike /home/gmod/mounts/cstrike \
    && rm -rf /home/gmod/temp

RUN mkdir -p /home/gmod/.steam/sdk32 /home/gmod/.steam/sdk64 \
    && cp /home/gmod/steamcmd/linux32/steamclient.so /home/gmod/.steam/sdk32/steamclient.so \
    && cp /home/gmod/steamcmd/linux64/steamclient.so /home/gmod/.steam/sdk64/steamclient.so

RUN echo '"mountcfg" {"cstrike" "/home/gmod/mounts/cstrike"}' > /home/gmod/server/garrysmod/cfg/mount.cfg \
    && mkdir -p /home/gmod/server/steam_cache/content /home/gmod/server/garrysmod/cache/srcds

# https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity
EXPOSE 27015
EXPOSE 27015/udp
EXPOSE 27005/udp

# data/ is a volume (gamemode data + sv.db, symlinked in).
RUN mkdir -p /home/gmod/server/garrysmod/data \
    && ln -sf data/sv.db /home/gmod/server/garrysmod/sv.db
VOLUME ["/home/gmod/server/garrysmod/data"]

ENV MAXPLAYERS="16"
ENV GAMEMODE="sandbox"
ENV MAP="gm_construct"
ENV PORT="27015"

COPY --chown=steam:steam assets/start.sh /home/gmod/start.sh
COPY --chown=steam:steam assets/health.sh /home/gmod/health.sh
RUN chmod +x /home/gmod/start.sh /home/gmod/health.sh

HEALTHCHECK --start-period=10s \
    CMD /home/gmod/health.sh

CMD ["/home/gmod/start.sh"]
