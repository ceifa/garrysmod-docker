#!/bin/bash
# Runs as root: remap the steam user to the host's PUID/PGID, check the mounts are
# readable, then drop to the server user (unless GMOD_USER=root) and exec the CMD.
set -e

GMOD_USER=${GMOD_USER:-steam}
RUN_AS=()

if [ "$(id -u)" -eq 0 ]; then
    CURRENT_UID=$(id -u steam)
    CURRENT_GID=$(id -g steam)
    PUID=${PUID:-$CURRENT_UID}
    PGID=${PGID:-$CURRENT_GID}

    if [ "$PGID" != "$CURRENT_GID" ]; then groupmod -o -g "$PGID" steam; fi
    if [ "$PUID" != "$CURRENT_UID" ]; then usermod  -o -u "$PUID" steam; fi

    if [ "$PUID" != "$CURRENT_UID" ] || [ "$PGID" != "$CURRENT_GID" ]; then
        echo "Remapping steam -> ${PUID}:${PGID}; fixing ownership under /home/gmod ..."
        chown -R steam:steam /home/gmod 2>/dev/null || true
    fi

    if [ "$GMOD_USER" != "root" ]; then RUN_AS=(gosu steam); fi
else
    PUID=$(id -u)
fi

gm="/home/gmod/server/garrysmod/gamemodes/${GAMEMODE:-sandbox}"
if [ -d "$gm" ] && ! "${RUN_AS[@]}" sh -c "test -r '$gm' && test -x '$gm'"; then
    cat >&2 <<EOF
ERROR: gamemode '${GAMEMODE:-sandbox}' at $gm is not readable by the server user (uid ${PUID}).
       This is almost always a bind-mount ownership mismatch, not a server bug.
         - Linux:   run with  -e PUID=\$(id -u) -e PGID=\$(id -g)  so the server matches your
                    files, or chown the mounted folder to that uid.
         - Windows: keep the project inside the WSL2 filesystem (e.g. ~/gmod), NOT under C:\\,
                    or use the ceifa/garrysmod:debian-root image (runs as root, reads any file).
EOF
    exit 1
fi

exec "${RUN_AS[@]}" "$@"
