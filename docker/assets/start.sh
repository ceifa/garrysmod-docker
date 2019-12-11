#!/bin/bash

if [ -n "${PRODUCTION}" ]; then
    MODE="production"
    # DISABLE AUTO LUA REFRESH IF PRODUCTION FLAG
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
    -port 27015 \
    +maxplayers "${MAXPLAYERS}" \
    +hostname \""${HOSTNAME}"\" \
    +gamemode "${GAMEMODE}" \
    +map "${MAP}" "${ARGS}"