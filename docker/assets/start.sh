#!/bin/bash

# UNION FILE SYSTEM
unionfs-fuse -o cow /server-volume=RW:/server-base=RO /server-union

if [ -n "${PRODUCTION}" ]; then
    MODE="production"
    # DISABLE AUTO LUA REFRESH IF PRODUCTION FLAG
    ARGS="-disableluarefresh ${ARGS}"
else
    MODE="development"
fi

# START THE SERVER
echo "Starting server on ${mode} mode..."
/server-union/srcds_run \
    -game garrysmod \
    -norestart \
    -strictportbind \
    -autoupdate \
    -steam_dir "/steamcmd" \
    -steamcmd_script "/update.txt" \
    -port 27015 \
    +maxplayers ${MAXPLAYERS} \
    +hostname "${HOSTNAME}" \
    +gamemode ${GAMEMODE} \
    +map ${MAP} \
    ${ARGS}