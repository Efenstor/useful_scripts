#!/bin/sh

dryrun=
dst_ext=otf
depth=

# Parse the named parameters
optstr="?hd:t"
while getopts $optstr opt
do
  case "$opt" in
    d) depth="$OPTARG" ;;
    t) dst_ext=ttf ;;
    :) echo "Missing argument for -$OPTARG" >&2
       exit 1
       ;;
  esac
done
shift $(expr $OPTIND - 1)

if [ $# -lt 2 ]; then
  echo
  echo "Usage: ttf2otf_batch.sh [options] <src_dir> <dst_dir>"
  echo
  echo "Options:"
  echo "  -d <num>: recursion depth"
  echo "  -t: convert to ttf (sanitize)"
  echo
  echo "Processing is always recursive, all non-existing dirs will be created."
  echo "Any otf files in the source dirs will be copied and sanitized as well."
  echo "Existing destinations files are overwritten silently."
  echo
  exit
fi

src_dir="$1"
dst_dir=$(realpath "$2")

cd "$src_dir"
files=$(find . ${depth:+-maxdepth $depth} -type f -iname "*.ttf" -o -iname "*.otf" | sort -n -f)

while [ -n "$files" ]; do

  f=$(echo "$files" | head -n 1 | cut -c 3-)

  srcd=$(dirname "$f")
  if [ "$srcd" = "." ]; then
    srcd=
  fi
  srcb=$(basename "$f")
  srcn="${srcb%.*}"
  dstd="$dst_dir"/"$srcd"
  dstf="$dstd"/"$srcn"."$dst_ext"
  echo "Converting \"$f\" to \"$dstf\""

  if [ ! "$dryrun" ]; then

    if [ ! -d "$dstd" ]; then
      mkdir -p "$dstd"
      if [ $? -ne 0 ]; then
        echo "Cannot create output directory"
        exit
      fi
    fi

    if [ -f "$dstf" ]; then
      rm -f "$dstf"
      if [ $? -ne 0 ]; then
        echo "Cannot overwrite existing file. Skipping..."
        files=$(echo "$files" | tail -n +2)  # Trim file list
        continue
      fi
    fi

    ots-sanitize "$f" "$dstf"
    if [ $? -ne 0 ]; then
      echo "Error converting the file. Skipping..."
      if [ -f "$dstf" ]; then
        rm -f "$dstf"
      fi
    fi

  fi
  files=$(echo "$files" | tail -n +2)  # Trim file list

done
