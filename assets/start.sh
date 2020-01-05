#!/bin/bash

if [ -n "${NAME}" ]; then
    ARGS="+hostname \"${NAME}\" ${ARGS}"
fi

if [ -n "${MAXPLAYERS}" ]; then
    ARGS="-maxplayers \"${MAXPLAYERS}\" ${ARGS}"
fi

if [ -n "${PRODUCTION}" ] && [ "${PRODUCTION}" -ne 0 ]; then
    MODE="production"
    ARGS="-disableluarefresh ${ARGS}"
else
    MODE="development"
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
    -port "${PORT}" \
    +gamemode "${GAMEMODE}" \
    +map "${MAP}" "${ARGS}"