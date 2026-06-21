#!/bin/bash
# debian-post installs GMod on first start, then hands off to start.sh.
/home/gmod/steamcmd/steamcmd.sh +runscript /home/gmod/update.txt +quit
echo '"mountcfg" {"cstrike" "/home/gmod/mounts/cstrike"}' > /home/gmod/server/garrysmod/cfg/mount.cfg

exec /home/gmod/start.sh
