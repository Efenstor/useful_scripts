#!/bin/sh

if [ $# -lt 2 ]; then
  echo "Usage: backup.sh <source> <destination>"
  echo "<destination> is the root where a dir with the <source> name will be created"
  exit
fi

rsync -avR --del "$1" "$2"

