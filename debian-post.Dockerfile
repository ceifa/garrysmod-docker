# BASE IMAGE
FROM debian:trixie-slim
# Set FINAL_USER=root to build the debian-post-root variant.
ARG FINAL_USER=steam

LABEL maintainer="ceifa"
LABEL description="A structured Garry's Mod dedicated server under a debian linux image"

ENV DEBIAN_FRONTEND=noninteractive
# HOME points at the server root so steamclient.so under .steam is found whether
# the final user is steam or root.
ENV HOME=/home/gmod

# Modern Debian dropped libssl1.1/libtinfo5/libncurses5 and renamed lib32gcc1/SDL1.2.
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get -y --no-install-recommends --no-install-suggests install \
        wget ca-certificates tar lib32gcc-s1 libgcc-s1 libcurl4-gnutls-dev:i386 \
        libcurl4:i386 libtinfo6:i386 lib32z1 lib32stdc++6 libncurses6:i386 \
        libcurl3-gnutls:i386 gdb libsdl2-2.0-0:i386 libfontconfig1 net-tools \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

# SET STEAM USER
RUN useradd -d /home/gmod -m steam
USER steam
RUN mkdir /home/gmod/server && mkdir /home/gmod/steamcmd

# INSTALL STEAMCMD
RUN wget -P /home/gmod/steamcmd/ https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xzf /home/gmod/steamcmd/steamcmd_linux.tar.gz -C /home/gmod/steamcmd \
    && rm -rf /home/gmod/steamcmd/steamcmd_linux.tar.gz

COPY assets/update.txt /home/gmod/update.txt

# SETUP CSS CONTENT (retry: a fresh SteamCMD can transiently fail the first
# app_update with "Missing configuration" yet still exit 0).
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

# SETUP BINARIES FOR x32 and x64 bits
RUN mkdir -p /home/gmod/.steam/sdk32 /home/gmod/.steam/sdk64 \
    && cp /home/gmod/steamcmd/linux32/steamclient.so /home/gmod/.steam/sdk32/steamclient.so \
    && cp /home/gmod/steamcmd/linux64/steamclient.so /home/gmod/.steam/sdk64/steamclient.so

# PORT FORWARDING
# https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity
EXPOSE 27015
EXPOSE 27015/udp
EXPOSE 27005/udp

# data/ is a volume so gamemode data + sv.db survive recreation (sv.db symlinked in).
RUN mkdir -p /home/gmod/server/garrysmod/data \
    && ln -sf data/sv.db /home/gmod/server/garrysmod/sv.db
VOLUME ["/home/gmod/server/garrysmod/data"]

# SET ENVIRONMENT VARIABLES
ENV MAXPLAYERS="16"
ENV GAMEMODE="sandbox"
ENV MAP="gm_construct"
ENV PORT="27015"

# ADD START SCRIPT
COPY --chown=steam:steam assets/start.sh /home/gmod/start.sh
RUN chmod +x /home/gmod/start.sh

# CREATE HEALTH CHECK
COPY --chown=steam:steam assets/health.sh /home/gmod/health.sh
RUN chmod +x /home/gmod/health.sh
HEALTHCHECK --start-period=10s \
    CMD /home/gmod/health.sh

COPY --chown=steam:steam assets/install.sh /home/gmod/install.sh
RUN chmod +x /home/gmod/install.sh

# Last step so the steam and root variants share every layer above.
USER ${FINAL_USER}

CMD ["/home/gmod/install.sh"]