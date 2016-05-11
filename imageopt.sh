#!/bin/sh

# Created by Error 800

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


readonly BASEDIR=$(cd "$(dirname "$0")" && pwd) # where the script is located
readonly CALLDIR=$(pwd)                         # where it was called from
readonly STATUS_SUCCESS=0                       # exit status for commands

# Script configuration
readonly DEPS=("convert")

# Internal field separator
IFS=","

# Script functions
function checkdeps () {
  for i in "${DEPS[@]}"; do
    :
    if ! command -v "$i" &>/dev/null; then
      echo "
$i not found, aborting...
      "
      exit 0
    fi
  done
}

function checkdir () {
  if [ ! -e "$1" ]; then
    if $create_dir; then
      mkdir -p "$1"
    else
      echo "Output path does not exist!"
      exit 0
    fi
  elif [ ! -d "$1" ]; then
    echo "Output path is not a directory!"
    exit 0
  fi
}

function usage () {
  echo "
Usage: $(basename $0) [options] file
    -a          write all output files, even if they exist
    -c          create output directory if it does not exist
    -f          output format (default: jpg)
    -o          output path (default: current directory)
    -q          output quality (default: 90)
    -w          list of output widths (default: (1920,1366,768,320))

    -h          this usage help text

    file        input image file

Compresses an image file and converts it to several different resolutions.

Example:
    $(basename $0) -a -c -f png -o images -w 1024,480 image.jpg
  "
  exit ${1:-0}
}

# Exit and show help if the command line is empty
[[ ! "$*" ]] && usage 1

# Check dependencies
checkdeps 1

# Default options
create_dir=false
output_dir="$CALLDIR"
output_format="jpg"
output_quality="90"
output_widths=(1920 1366 768 320)
overwrite=false

# Parse command line options
while getopts acf:o:q:w: option; do
  case $option in
    a) overwrite=true ;;
    c) create_dir=true ;;
    f) output_format="$OPTARG" ;;
    o) output_dir="$OPTARG" ;;
    q) output_quality="$OPTARG" ;;
    w) output_widths=($OPTARG) ;;
    h) usage ;;
    \?) usage 1 ;;
  esac
done
shift $(($OPTIND - 1)); # take out the option flags

# Check output directory
checkdir "$output_dir"

# Filenames
file_name="$(basename $1)"
file_path="$1"

# Do the work

:

# Convert images

for width in "${output_widths[@]}"; do
  if [ ! -e "${output_dir%/}/${1%%.*}-$width.$output_format" ] ||\
     $overwrite; then
     convert "$file_path" -strip -resize "$width"x -quality "$output_quality"\
             "${output_dir%/}/${file_name%%.*}-$width.$output_format"
  fi
done

