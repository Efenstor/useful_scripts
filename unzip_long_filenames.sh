#!/bin/sh
# Copyleft Efenstor

# Help
if [ $# -lt 1 ]; then
  echo "Usage: unzip_long_filenames <file.zip> [max_filename_len] [max_dirname_len]"
  exit
fi

# Params
if [ "$2" ]; then
  maxflen=$2
else
  maxflen=250
fi
if [ "$3" ]; then
  maxdlen=$3
else
  maxdlen=$maxflen
fi

# Job
zipinfo -1 "$1" | while read i
do
  # Is a file?
  if ! echo "$i" | grep "/$" > /dev/null; then
    isfile=1
  fi

  # Calling dirname on a dir can return "."
  if [ $isfile ]; then
    dir=$(dirname "$i")
  else
    dir="$i"
  fi

  # Use cut instead of substitutions to keep comparibility with Boune shell
  dir_short=$(echo "$dir" | cut -c-$maxdlen | iconv -c)
  if [ $isfile ]; then
    # File
    f=$(basename "$i")
    ext="${f##*.}"
    fname="${f%.*}"
    # iconv -c is to workaround the ancient unfixed bug in coreutils:
    # https://stackoverflow.com/a/18719951
    # http://lists.gnu.org/archive/html/bug-coreutils/2006-07/msg00044.html
    short="$dir_short"/$(echo "$fname" | cut -c-$maxflen | iconv -c)."$ext"
    echo "Extracting \"$i\" as \"$short\""
    unzip -p -c "$1" "$i" > "$short"
    if [ $? -ne 0 ]; then exit; fi
  elif [ ! -d "$i" ]; then
    # Dir
    mkdir "$dir_short"
    if [ $? -ne 0 ]; then exit; fi
  fi
done

