#!/bin/bash
/home/gmod/steamcmd/steamcmd.sh +runscript /home/gmod/update.txt +quit
echo '"mountcfg" {"cstrike" "/home/gmod/mounts/cstrike"}' > /home/gmod/server/garrysmod/cfg/mount.cfg

/home/gmod/start.sh