#!/bin/bash
if ! netstat -ln | grep -E "[:.]${PORT}[[:space:]].*LISTEN" > /dev/null;
then
    exit 1
fi
