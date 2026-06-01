# BASE IMAGE
FROM ubuntu:26.04

LABEL maintainer="ceifa"
LABEL description="A structured Garry's Mod dedicated server under a ubuntu linux image"

ENV DEBIAN_FRONTEND=noninteractive
# INSTALL NECESSARY PACKAGES (same i386 set as the Debian image; 24.04+ kept the
# transitional names through the t64 transition).
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get -y --no-install-recommends --no-install-suggests install \
        wget ca-certificates tar lib32gcc-s1 libgcc-s1 libcurl4-gnutls-dev:i386 \
        libcurl4:i386 libtinfo6:i386 lib32z1 lib32stdc++6 libncurses6:i386 \
        libcurl3-gnutls:i386 gdb libsdl2-2.0-0:i386 libfontconfig1 net-tools unzip \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

# SET STEAM USER
RUN useradd -d /home/gmod -m steam
USER steam
RUN mkdir /home/gmod/server && mkdir /home/gmod/steamcmd

# INSTALL STEAMCMD
RUN wget -P /home/gmod/steamcmd/ https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xvzf /home/gmod/steamcmd/steamcmd_linux.tar.gz -C /home/gmod/steamcmd \
    && rm -rf /home/gmod/steamcmd/steamcmd_linux.tar.gz

# SETUP STEAMCMD TO DOWNLOAD GMOD SERVER
COPY assets/update.txt /home/gmod/update.txt
RUN /home/gmod/steamcmd/steamcmd.sh +runscript /home/gmod/update.txt +quit

# SETUP CSS CONTENT
RUN /home/gmod/steamcmd/steamcmd.sh \
    +force_install_dir /home/gmod/temp \
    +login anonymous \
    +app_update 232330 validate \
    +quit
RUN mkdir /home/gmod/mounts && mv /home/gmod/temp/cstrike /home/gmod/mounts/cstrike
RUN rm -rf /home/gmod/temp

# SETUP BINARIES FOR x32 and x64 bits
RUN mkdir -p /home/gmod/.steam/sdk32 \
    && cp -v /home/gmod/steamcmd/linux32/steamclient.so /home/gmod/.steam/sdk32/steamclient.so \
    && mkdir -p /home/gmod/.steam/sdk64 \
    && cp -v /home/gmod/steamcmd/linux64/steamclient.so /home/gmod/.steam/sdk64/steamclient.so

# SET GMOD MOUNT CONTENT
RUN echo '"mountcfg" {"cstrike" "/home/gmod/mounts/cstrike"}' > /home/gmod/server/garrysmod/cfg/mount.cfg

# CREATE CACHE FOLDERS
RUN mkdir -p /home/gmod/server/steam_cache/content && mkdir -p /home/gmod/server/garrysmod/cache/srcds

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

# START THE SERVER
CMD ["/home/gmod/start.sh"]