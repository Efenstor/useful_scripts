#!/bin/sh

if [ $? -lt 1 ]; then
  echo "Usage: sanitize_ttf.sh <dir>"
  exit
fi

find "$1" -iname "*.ttf" \( -print -exec ots-sanitize '{}' '{}' \; \)

