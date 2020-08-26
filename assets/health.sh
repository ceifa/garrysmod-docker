if ! [ "$(netstat -l | grep "${PORT}.*LISTEN")" ];
then
    exit 1
fi