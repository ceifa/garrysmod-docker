#!/bin/bash

if [ -z "${HOSTNAME}" ]; then
    ARGS="+hostname \"${HOSTNAME}\" ${ARGS}"
fi

if [ -z "${MAXPLAYERS}" ]; then
    ARGS="+maxplayers \"${MAXPLAYERS}\" ${ARGS}"
fi

if [ -n "${PRODUCTION}" ] && [ "${PRODUCTION}" -ne 0 ]; then
    MODE="production"
    ARGS="-disableluarefresh ${ARGS}"
else
    MODE="development"
    ARGS="-gdb gdb -debug ${ARGS}"
fi

# START THE SERVER
echo "Starting server on ${MODE} mode..."

screen -A -m -S server /server/srcds_run \
    -game garrysmod \
    -norestart \
    -strictportbind \
    -autoupdate \
    -steam_dir "/steamcmd" \
    -steamcmd_script "/update.txt" \
    -port 27015 \
    +gamemode "${GAMEMODE}" \
    +map "${MAP}" "${ARGS}"