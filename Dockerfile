# BASE IMAGE
FROM ubuntu:bionic

LABEL maintainer="ceifa"

# INSTALL NECESSARY PACKAGES
RUN apt-get update && apt-get -y --no-install-recommends --no-install-suggests install \
    wget lib32gcc1 lib32stdc++6 lib32tinfo5 ca-certificates screen

# CLEAN UP
RUN apt-get clean
RUN rm -rf /tmp/* /var/lib/apt/lists/*

# PRE-SETUP DIRECTORIES
RUN mkdir /steamcmd \
    && mkdir /server

# SET STEAM USER
RUN groupadd steam \
    && useradd -m -r -g steam steam \
    && chown -vR steam:steam /server /steamcmd
USER steam

# INSTALL STEAMCMD
WORKDIR /steamcmd
RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
RUN tar -xvzf steamcmd_linux.tar.gz
WORKDIR /

# SETUP STEAMCMD TO DOWNLOAD GMOD SERVER AND CSS CONTENT
ADD assets/update.txt /update.txt
RUN /steamcmd/steamcmd.sh +runscript /update.txt +quit

# SET GMOD MOUNT CONTENT
RUN echo '"mountcfg" {"cstrike" "/server/content/css/cstrike"}' > /server/garrysmod/cfg/mount.cfg

# PORT FORWARDING
# https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity
EXPOSE 27015
EXPOSE 27015/udp
EXPOSE 27005/udp

# SET ENVIRONMENT VARIABLES
ENV MAXPLAYERS="16"
ENV HOSTNAME="Garry's Mod"
ENV GAMEMODE="sandbox"
ENV MAP="gm_construct"

# START THE SERVER
ADD assets/start.sh /start.sh
CMD ["/start.sh"]