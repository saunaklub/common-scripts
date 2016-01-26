#!/usr/bin/sh

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
readonly DEPS=("ffmpeg")

# Script functions
function checkdeps () {
  for i in "${DEPS[@]}"; do
    :
    if ! command -v "$i" &>/dev/null; then
      echo "
$i not found, aborting...
      "
      exit ${1:-0}
    fi
  done
}

function usage () {
  echo "
Usage: $(basename $0) [options] file
    -b          target bitrate

    -h          this usage help text

    file        input audio file

Converts an audio input file to mp3 and ogg formats.

Example:
    $(basename $0) -b 320k audio.wav
  "
  exit ${1:-0}
}

# Exit and show help if the command line is empty
[[ ! "$*" ]] && usage 1

# Check dependencies
checkdeps 1

# Initialise options
rate_audio="128k"

# Parse command line options
while getopts nsa:v: option; do
  case $option in
    b) rate_audio="$OPTARG" ;;
    h) usage ;;
    \?) usage 1 ;;
  esac
done
shift $(($OPTIND - 1)); # take out the option flags

# Do the work

:
ffmpeg -i "$1" -c:a libmp3lame -b:a "$rate_audio" "${1%%.*}".mp3
ffmpeg -i "$1" -c:a libvorbis -b:a "$rate_audio" "${1%%.*}".ogg

