#!/bin/bash
SERVER_ARGS=()

if [ -n "${NAME}" ];
then
    SERVER_ARGS+=(+hostname "${NAME}")
fi

if [ -n "${GSLT}" ];
then
    SERVER_ARGS+=(+sv_setsteamaccount "${GSLT}")
fi

if [ -n "${AUTHKEY}" ];
then
    SERVER_ARGS+=(-authkey "${AUTHKEY}")
fi

if [ -n "${PRODUCTION}" ] && [ "${PRODUCTION}" -ne 0 ];
then
    MODE="production"
    SERVER_ARGS+=(-disableluarefresh)
else
    MODE="development"
    SERVER_ARGS+=(-gdb gdb -debug)
fi

echo "Starting server on ${MODE} mode..."

# exec so srcds becomes PID 1 and receives signals directly (clean shutdown).
exec /home/gmod/server/"${SRCDS_BINARY:-srcds_run}" \
    -game garrysmod \
    -norestart \
    -strictportbind \
    -autoupdate \
    -steam_dir "/home/gmod/steamcmd" \
    -steamcmd_script "/home/gmod/update.txt" \
    -port "${PORT}" \
    -maxplayers "${MAXPLAYERS}" \
    +gamemode "${GAMEMODE}" \
    +map "${MAP}" "${SERVER_ARGS[@]}" ${ARGS}
