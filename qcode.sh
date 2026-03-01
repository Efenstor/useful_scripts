#!/bin/sh
# Copyleft Efenstor 2024-2026
# Requirements: qrencode imv

if [ ! "$(which barcode)" ]; then
  echo "Please install the \"barcode\" utility"
  exit
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Convert text to big barcode for scanning with a phone"
  echo "Usage: bcode.sh [text]"
  exit
fi

if [ ! "$1" ]; then
  read -p "Enter the string: " str
else
  str="$1"
fi
qrencode "$str" -o - | imv -
