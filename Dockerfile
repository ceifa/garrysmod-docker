# syntax=docker/dockerfile:1
#
# One Dockerfile for all Debian variants, via build args:
#   debian-root      FINAL_USER=root
#   debian-x64       STEAM_BETA="-beta x86-64" SRCDS_BINARY=srcds_run_x64
#   debian-x64-root  the x64 args + FINAL_USER=root
# GMod and CSS download in parallel stages; the final stage assembles both.

ARG BASE_IMAGE=debian:trixie-slim

# base: OS packages + SteamCMD, shared by every stage
FROM ${BASE_IMAGE} AS base
ARG STEAM_BETA=""
ENV DEBIAN_FRONTEND=noninteractive
# HOME under the server root so .steam/steamclient.so resolves for steam and root.
ENV HOME=/home/gmod

# Modern Debian renamed/dropped the old i386 libs (libssl1.1, libtinfo5, lib32gcc1...).
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get -y --no-install-recommends --no-install-suggests install \
        wget ca-certificates tar lib32gcc-s1 libgcc-s1 libcurl4-gnutls-dev:i386 \
        libcurl4:i386 libtinfo6:i386 lib32z1 lib32stdc++6 libncurses6:i386 \
        libcurl3-gnutls:i386 gdb libsdl2-2.0-0:i386 libfontconfig1 net-tools unzip \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

# Build as steam so content is steam-owned; the root variant only flips USER at the end.
RUN useradd -d /home/gmod -m steam
USER steam
RUN mkdir /home/gmod/server /home/gmod/steamcmd

# +quit pre-warms SteamCMD's self-update.
RUN wget -P /home/gmod/steamcmd/ https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xzf /home/gmod/steamcmd/steamcmd_linux.tar.gz -C /home/gmod/steamcmd \
    && rm -rf /home/gmod/steamcmd/steamcmd_linux.tar.gz \
    && /home/gmod/steamcmd/steamcmd.sh +quit

RUN mkdir -p /home/gmod/.steam/sdk32 /home/gmod/.steam/sdk64 \
    && cp /home/gmod/steamcmd/linux32/steamclient.so /home/gmod/.steam/sdk32/steamclient.so \
    && cp /home/gmod/steamcmd/linux64/steamclient.so /home/gmod/.steam/sdk64/steamclient.so

# Kept for srcds -autoupdate. ${STEAM_BETA:+ ...} adds the beta flag only when set.
RUN printf '@ShutdownOnFailedCommand 0\n@NoPromptForPassword 1\n\nforce_install_dir /home/gmod/server\nlogin anonymous\napp_update 4020%s validate\nquit\n' "${STEAM_BETA:+ ${STEAM_BETA}}" > /home/gmod/update.txt

# gmod: download the dedicated server (parallel with css)
FROM base AS gmod
ARG SRCDS_BINARY=srcds_run
# Retry: a fresh SteamCMD can fail the first app_update yet exit 0.
RUN for i in 1 2 3 4 5; do \
        /home/gmod/steamcmd/steamcmd.sh +runscript /home/gmod/update.txt +quit; \
        [ -f "/home/gmod/server/${SRCDS_BINARY}" ] && break; \
        echo "GMod download attempt $i incomplete, retrying..."; \
    done; \
    [ -f "/home/gmod/server/${SRCDS_BINARY}" ]

# css: download Counter-Strike: Source content (parallel with gmod)
FROM base AS css
RUN for i in 1 2 3 4 5; do \
        /home/gmod/steamcmd/steamcmd.sh \
            +force_install_dir /home/gmod/css \
            +login anonymous \
            +app_update 232330 validate \
            +quit; \
        [ -d /home/gmod/css/cstrike ] && break; \
        echo "CSS download attempt $i incomplete, retrying..."; \
    done; \
    [ -d /home/gmod/css/cstrike ]

# final: assemble the runnable image
FROM base AS final
ARG SRCDS_BINARY=srcds_run
ARG FINAL_USER=steam

LABEL maintainer="ceifa"
LABEL description="A structured Garry's Mod dedicated server under a debian linux image"

COPY --from=gmod --chown=steam:steam /home/gmod/server /home/gmod/server
COPY --from=css --chown=steam:steam /home/gmod/css/cstrike /home/gmod/mounts/cstrike

# data/ is a volume (gamemode data + sv.db, symlinked in); addons/gamemodes stay
# non-volumes so they can be baked in or bind-mounted.
RUN echo '"mountcfg" {"cstrike" "/home/gmod/mounts/cstrike"}' > /home/gmod/server/garrysmod/cfg/mount.cfg \
    && mkdir -p /home/gmod/server/steam_cache/content /home/gmod/server/garrysmod/cache/srcds \
    && mkdir -p /home/gmod/server/garrysmod/data \
    && ln -sf data/sv.db /home/gmod/server/garrysmod/sv.db
VOLUME ["/home/gmod/server/garrysmod/data"]

# https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity
EXPOSE 27015
EXPOSE 27015/udp
EXPOSE 27005/udp

ENV MAXPLAYERS="16"
ENV GAMEMODE="sandbox"
ENV MAP="gm_construct"
ENV PORT="27015"
ENV SRCDS_BINARY=${SRCDS_BINARY}

COPY --chown=steam:steam assets/start.sh /home/gmod/start.sh
COPY --chown=steam:steam assets/health.sh /home/gmod/health.sh
RUN chmod +x /home/gmod/start.sh /home/gmod/health.sh

HEALTHCHECK --start-period=10s \
    CMD /home/gmod/health.sh

USER ${FINAL_USER}

CMD ["/home/gmod/start.sh"]
