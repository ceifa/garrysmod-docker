# BASE IMAGE
FROM debian:buster-slim

LABEL maintainer="ceifa"
LABEL description="A structured Garry's Mod dedicated server under a debian linux image"

ENV DEBIAN_FRONTEND noninteractive
# INSTALL NECESSARY PACKAGES
RUN dpkg --add-architecture i386 && apt-get update && apt-get -y --no-install-recommends --no-install-suggests install \
    wget ca-certificates tar gcc g++ libgcc1 libssl1.1 libtinfo5 lib32z1 gdb libsdl1.2debian libfontconfig net-tools

# CLEAN UP
RUN apt-get clean
RUN rm -rf /tmp/* /var/lib/apt/lists/*

# SET STEAM USER
RUN useradd -d /home/gmod -m steam
USER steam
RUN mkdir /home/gmod/server && mkdir /home/gmod/steamcmd

# INSTALL STEAMCMD
RUN wget -P /home/gmod/steamcmd/ https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xvzf /home/gmod/steamcmd/steamcmd_linux.tar.gz -C /home/gmod/steamcmd \
    && rm -rf /home/gmod/steamcmd/steamcmd_linux.tar.gz

# SETUP STEAMCMD TO DOWNLOAD GMOD SERVER
COPY assets/update-x64.txt /home/gmod/update.txt
RUN /home/gmod/steamcmd/steamcmd.sh +runscript /home/gmod/update.txt +quit

# SETUP CSS CONTENT
RUN /home/gmod/steamcmd/steamcmd.sh +login anonymous \
    +force_install_dir /home/gmod/temp \
    +app_update 232330 validate \
    +quit
RUN mkdir /home/gmod/mounts && mv /home/gmod/temp/cstrike /home/gmod/mounts/cstrike
RUN rm -rf /home/gmod/temp

# SETUP BINARIES FOR x64 bits
RUN mkdir -p /home/gmod/.steam/sdk64 \
    && cp -v /home/gmod/steamcmd/linux64/steamclient.so /home/gmod/.steam/sdk64/steamclient.so

# SET GMOD MOUNT CONTENT
RUN echo '"mountcfg" {"cstrike" "/home/gmod/mounts/cstrike"}' > /home/gmod/server/garrysmod/cfg/mount.cfg

# CREATE DATABASE FILE
RUN touch /home/gmod/server/garrysmod/sv.db

# PORT FORWARDING
# https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity
EXPOSE 27015
EXPOSE 27015/udp
EXPOSE 27005/udp

# SET ENVIRONMENT VARIABLES
ENV MAXPLAYERS="16"
ENV GAMEMODE="sandbox"
ENV MAP="gm_construct"
ENV PORT="27015"

# ADD START SCRIPT
COPY --chown=steam:steam assets/start-x64.sh /home/gmod/start.sh
RUN chmod +x /home/gmod/start.sh

# CREATE HEALTH CHECK
COPY --chown=steam:steam assets/health.sh /home/gmod/health.sh
RUN chmod +x /home/gmod/health.sh
HEALTHCHECK --start-period=10s \
    CMD /home/gmod/health.sh

# START THE SERVER
CMD ["/home/gmod/start.sh"]