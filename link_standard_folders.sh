#!/bin/sh
# Replaces standard folders with symbolic links

# Destination dirs (empty = ignore)
DESKTOP=
DOWNLOAD=/media/data/Downloads
TEMPLATES=/media/data/Templates
PUBLIC=/media/data/Public
DOCUMENTS=/media/data/Documents
MUSIC=/media/data/Music
PICTURES=/media/data/Pictures
VIDEOS=/media/data/Videos

replace () {
  # Skip if set to ignore
  if [ ! "$2" ]; then
    return
  fi
  
  # What to do with the existing thing
  if [ -d "$1" ]; then
    # Dir
    if [ -L "$1" ]; then
      # Existing symbolic link
      rm "$1"
    elif [ "$(ls -A1 "$1")" ]; then
      # A non-empty dir
      mv "$1" "$1".bak
    else
      # An empty dir
      rmdir "$1"
    fi
  elif [ -f "$1" ]; then
    # File of some kind
    mv "$1" "$1".bak
  elif [ -L "$1" ]; then
    # Symbolic link leading to nowhere
    rm "$1"
  fi

  # Create a new link
  ln -s "$2" "$1"
}

replace "$(xdg-user-dir DESKTOP)" "$DESKTOP"
replace "$(xdg-user-dir DOWNLOAD)" "$DOWNLOAD"
replace "$(xdg-user-dir TEMPLATES)" "$TEMPLATES"
replace "$(xdg-user-dir PUBLICSHARE)" "$PUBLIC"
replace "$(xdg-user-dir DOCUMENTS)" "$DOCUMENTS"
replace "$(xdg-user-dir MUSIC)" "$MUSIC"
replace "$(xdg-user-dir PICTURES)" "$PICTURES"
replace "$(xdg-user-dir VIDEOS)" "$VIDEOS"

