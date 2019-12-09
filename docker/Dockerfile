# BASE IMAGE
FROM ubuntu:bionic

LABEL maintainer="ceifa"

# INSTALL NECESSARY PACKAGES
RUN apt-get update && apt-get -y --no-install-recommends --no-install-suggests install \
    wget lib32gcc1 lib32stdc++6 lib32tinfo5 ca-certificates unionfs-fuse

# CLEAN UP
RUN apt-get clean
RUN rm -rf /tmp/* /var/lib/apt/lists/*

# INSTALL STEAMCMD
RUN mkdir /steamcmd
WORKDIR /steamcmd
RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
RUN tar -xvzf steamcmd_linux.tar.gz
WORKDIR /

# SETUP STEAMCMD TO DOWNLOAD GMOD SERVER AND CSS CONTENT
RUN mkdir /server-base
ADD assets/update.txt /update.txt
RUN /steamcmd/steamcmd.sh +runscript /update.txt +quit

# SET GMOD MOUNT CONTENT
RUN echo '"mountcfg" {"cstrike" "/server/content/css/cstrike"}' > /server-base/garrysmod/cfg/mount.cfg

# SET VOLUME
RUN mkdir /server-volume
RUN mkdir /server-union

# PORT FORWARDING
# https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity
EXPOSE 27015
EXPOSE 27015/udp

# SET ENVIRONMENT VARIABLES
ENV PORT="27015"
ENV MAXPLAYERS="16"
ENV HOSTNAME="Garry's Mod"
ENV GAMEMODE="sandbox"
ENV MAP="gm_construct"

# START THE SERVER
ADD assets/start.sh /start.sh
CMD ["/bin/sh", "/start.sh"]