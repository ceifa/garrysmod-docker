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

# Update once here instead of via srcds_run's -autoupdate, which forces a crash-restart
# loop. Then run once with -norestart and let Docker's restart policy handle recovery.
if [ "${AUTOUPDATE:-1}" != "0" ];
then
    echo "Updating server using Steam..."
    /home/gmod/steamcmd/steamcmd.sh +runscript /home/gmod/update.txt +quit \
        || echo "WARNING: Steam update failed; starting with the installed version."
fi

echo "Starting server on ${MODE} mode..."

# exec so srcds becomes PID 1 and receives signals directly (clean shutdown).
exec /home/gmod/server/"${SRCDS_BINARY:-srcds_run}" \
    -game garrysmod \
    -norestart \
    -strictportbind \
    -port "${PORT}" \
    -maxplayers "${MAXPLAYERS}" \
    +gamemode "${GAMEMODE}" \
    +map "${MAP}" "${SERVER_ARGS[@]}" ${ARGS}
