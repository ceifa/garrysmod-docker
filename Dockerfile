# BASE IMAGE
FROM ubuntu:bionic

LABEL maintainer="ceifa"
LABEL description="A structured Garry's Mod dedicated server under a ubuntu linux image"

# INSTALL NECESSARY PACKAGES
RUN apt-get update && apt-get -y --no-install-recommends --no-install-suggests install \
    wget lib32gcc1 lib32stdc++6 lib32tinfo5 ca-certificates screen tar bzip2 gzip unzip

# CLEAN UP
RUN apt-get clean
RUN rm -rf /tmp/* /var/lib/apt/lists/*

# SET STEAM USER
RUN mkdir server && mkdir /steamcmd
RUN groupadd steam \
    && useradd -m -r -g steam steam \
    && chown -vR steam:steam /server /steamcmd
USER steam

# INSTALL STEAMCMD
WORKDIR /steamcmd
RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
RUN tar -xvzf steamcmd_linux.tar.gz
WORKDIR /

# SETUP STEAMCMD TO DOWNLOAD GMOD SERVER
COPY assets/update.txt /update.txt
RUN /steamcmd/steamcmd.sh +runscript /update.txt +quit

# SETUP CSS CONTENT
RUN /steamcmd/steamcmd.sh +login anonymous \
    +force_install_dir /server/content/css \
    +app_update 232330 validate \
    +quit
RUN mv /server/content/css/cstrike /server/content
RUN rm -rf /server/content/css

# SET GMOD MOUNT CONTENT
RUN echo '"mountcfg" {"cstrike" "/server/content/cstrike"}' > /server/garrysmod/cfg/mount.cfg

# CREATE DATABASE FILE
RUN touch /server/garrysmod/sv.db

# PORT FORWARDING
# https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity
EXPOSE 27015
EXPOSE 27015/udp
EXPOSE 27005/udp

# SET ENVIRONMENT VARIABLES
ENV MAXPLAYERS="16"
ENV GAMEMODE="sandbox"
ENV MAP="gm_construct"

# ADD START SCRIPT
COPY --chown=steam:steam assets/start.sh /server/start.sh
RUN chmod +x /server/start.sh

# START THE SERVER
CMD ["/server/start.sh"]