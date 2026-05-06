#!/bin/sh
# Copyleft 2026 Efenstor

# Default page size
page_width_default=297
page_height_default=210

# Misc
system_required="gs pdfjam"

findpkg() {
  if which "apt-file" > /dev/null; then
    # Debian-based system
    pkg=$(apt-file search "/bin/$1" | grep /bin/"$1"$ | sed "s/: .*//" | head -n1)
  elif which "pacman" > /dev/null; then
    # Arch-based system
    pkg=$(pacman -F "$1" | grep -B1 /bin/"$1"$ | head -n1 | sed "s/ [0-9].*$//" | sed "s/.*\///")
  fi
  if [ "$pkg" ]; then
    printf "The missing tool found in the package \"$pkg\".\n"
  fi
}

# Check for the system requirements
for i in $system_required
do
  if [ ! $(which "$i") ]; then
    printf "The \"$i\" tool was not found on your system.\n"
    findpkg "$i"
    exit 1
  fi
done            

# Help
if [ $# -lt 2 ]; then
  echo "
Cut and rearrange PDF files with booklet page spreads into sheets for printing

Usage: make_booklet.sh <src_base_name> <dest_base_name>

Base name is the first portion of file name, which may be preceded by path.
For example, for files named booklet01.pdf, booklet02.pdf, etc. specify base
name \"booklet\": all files beginning with \"booklet\" will be used in
numerical order.
"
  exit
fi

# Default page size
dpi=72
pw_pt_default=$(echo "$page_width_default * ($dpi / 25.4)" | bc -l)
ph_pt_default=$(echo "$page_height_default * ($dpi / 25.4)" | bc -l)

# Base names
src_dir=$(dirname "$1")
src_base=$(basename "$1")
dst_dir=$(dirname "$2")
dst_base=$(basename "$2")

# Make the list of source PDF files
files=$(find "$src_dir" -maxdepth 1 -type f -iname "$src_base*.pdf" | sort -n -f)
files_cnt=$(echo "$files" | wc -l)
if [ $(( $files_cnt - $files_cnt / 2 * 2 )) -eq 1 ]; then
  echo "Odd number of source sheets, the final result will be wrong!"
  exit
fi

# Make a temporary directory
split_pages_dir=$(mktemp -d -p "$dst_dir")

# Split pages into left and right halves
n=1
while [ -n "$files" ]; do
  f=$(echo "$files" | head -n 1)

  # Get page size
  pdims=$(gs -dBATCH -dQUIET -dPDFINFO -dNODISPLAY booklet_04.pdf 2>&1 | sed -n "s/Page 1 MediaBox: \[\(.*\)\].*/\1/p")
  if [ ! "$pdims" ]; then
    echo "WARNING! Cannot determine page dimensions, using default ($page_width_default mm x $page_height_default mm)"
    pdim1=0
    pdim2=0
    pdim3=$pw_pt_default
    pdim4=$ph_pt_default
  else
    pdim1=$(echo "$pdims" | cut -d ' ' -f 1)
    pdim2=$(echo "$pdims" | cut -d ' ' -f 2)
    pdim3=$(echo "$pdims" | cut -d ' ' -f 3)
    pdim4=$(echo "$pdims" | cut -d ' ' -f 4)
  fi
  pdimm=$(echo "$pdim1 + ($pdim3-$pdim1) / 2" | bc -l)

  # Calculate destination page numbers for the halves (not the best algorithm
  # in the world but it works)
  if [ $n -le $(( $files_cnt / 2 )) ]; then
    dst_right=$(( $n * 2 - 1 ))
    dst_left=$(( $dst_right - 1 ))
    if [ $dst_left -lt 1 ]; then dst_left=1; fi
  else
    dst_right=$(( ($files_cnt - $n + 1) * 2 ))
    dst_left=$(( $dst_right + 1 ))
    if [ $dst_left -gt $files_cnt ]; then dst_left=$files_cnt; fi
  fi

  # Split
  l_file="$split_pages_dir"/$dst_left"L.pdf"
  r_file="$split_pages_dir"/$dst_right"R.pdf"
  gs -o "$l_file" -sDEVICE=pdfwrite \
    -c "[/CropBox [$pdim1 $pdim2 $pdimm $pdim4] /PAGES pdfmark" \
    -f "$f"
  gs -o "$r_file" -sDEVICE=pdfwrite \
    -c "[/CropBox [$pdimm $pdim2 $pdim3 $pdim4] /PAGES pdfmark" \
    -f "$f"

  n=$(( $n + 1 ))
  files=$(echo "$files" | tail -n +2)  # Trim file list
done

# Make destination directory
if [ ! -d "$dst_dir" ]; then
  mkdir "$dst_dir"
fi

# Combine pages
n=1
outfiles=
while [ $n -le $files_cnt ]; do
  input_left="$split_pages_dir"/"$n"L.pdf
  input_right="$split_pages_dir"/"$n"R.pdf
  outfile="$dst_dir"/"$dst_base"_$(printf "%04d" $n).pdf
  pdfjam -q "$input_left" "$input_right" --nup 2x1 --landscape --outfile "$outfile" 
  n=$(( $n + 1 ))
done

# Delete the temporary dir
rm -rf "$split_pages_dir"

