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

function checkres () {
  eval $(ffprobe -loglevel error -print_format flat=sep_char="_" \
    -select_streams v:0 -show_entries stream=width $1)
  eval $(ffprobe -loglevel error -print_format flat=sep_char="_" \
    -select_streams v:0 -show_entries stream=height $1)
}

function usage () {
  echo "
Usage: $(basename $0) [options] file
    -a          audio target bitrate (default: 128k)
    -v          video target bitrate (default: 1000k)
    -s          silent. remove audio

    -n          do not create screenshot
    -r          do not crop, throw an error instead

    -h          this usage help text

    file        input video file

Converts a video input file to h264, webm and ogv formats.
Saves a screenshot of the first frame as jpg.
Crops the video by 1px if width or height is uneven (h264 encoder limitation).

Example:
    $(basename $0) -v 3000k -s video.mpeg
  "
  exit ${1:-0}
}

# Exit and show help if the command line is empty
[[ ! "$*" ]] && usage 1

# Check dependencies
checkdeps 1

# Default options
rate_audio="128k"
rate_video="1000k"
screen=true
crop=true
audio=true

# Parse command line options
while getopts nrsa:v: option; do
  case $option in
    a) rate_audio="$OPTARG" ;;
    v) rate_video="$OPTARG" ;;
    n) screen=false ;;
    r) crop=false ;;
    s) audio=false ;;
    h) usage ;;
    \?) usage 1 ;;
  esac
done
shift $(($OPTIND - 1)); # take out the option flags

# Check video resolution
checkres $1

# Files
videofile="$1"

# Do the work

:

# Crop video if width and/or height is uneven
if [ $((streams_stream_0_width%2)) -eq 1 ] && \
   [ $((streams_stream_0_height%2)) -eq 1 ]; then
  if "$crop"; then
    ffmpeg -i "$1" -vf "crop=w=(in_w)-1:h=(in_h)-1:x=0:y=0" /tmp/$1
    videofile="/tmp/$1"
  else
    echo Input width and height are uneven-numbered:
    echo Width: $streams_stream_0_width
    echo Height: $streams_stream_0_height
    echo Aborting...
    exit 1
  fi
elif [ $((streams_stream_0_width%2)) -eq 1 ]; then
  if "$crop"; then
    ffmpeg -i "$1" -vf "crop=w=(in_w)-1:h=(in_h):x=0:y=0" /tmp/$1
    videofile="/tmp/$1"
  else
    echo Input width is uneven-numbered:
    echo Width: $streams_stream_0_width
    echo Aborting...
    exit 1
  fi
elif [ $((streams_stream_0_height%2)) -eq 1 ]; then
  if "$crop"; then
    ffmpeg -i "$1" -vf "crop=w=(in_w)-1:h=(in_h)-1:x=0:y=0" /tmp/$1
    videofile="/tmp/$1"
  else
    echo Input height is uneven-numbered:
    echo Height: $streams_stream_0_height
    echo Aborting...
    exit 1
  fi
fi

# Convert
if "$audio"; then
  ffmpeg -i "$videofile" -c:a aac -b:a "$rate_audio" -c:v libx264 \
    -b:v "$rate_video" -pix_fmt yuv420p -strict -2 "${1%%.*}"-web.mp4
  ffmpeg -i "$videofile" -c:a libvorbis -b:a "$rate_audio" -c:v libvpx \
    -b:v "$rate_video" "${1%%.*}"-web.webm
  ffmpeg -i "$videofile" -c:a libvorbis -b:a "$rate_audio" -c:v libtheora \
    -b:v "$rate_video" "${1%%.*}"-web.ogv
else
  ffmpeg -i "$videofile" -an -c:v libx264 -b:v "$rate_video" -pix_fmt yuv420p \
    "${1%%.*}"-web.mp4
  ffmpeg -i "$videofile" -an -c:v libvpx -b:v "$rate_video" "${1%%.*}"-web.webm
  ffmpeg -i "$videofile" -an -c:v libtheora -b:v "$rate_video" "${1%%.*}"-web.ogv
fi

# Save screenshot
if "$screen"; then
  ffmpeg -ss 00:00:00 -i "$videofile" -vframes 1 -q:v 2 "${1%%.*}"-web.jpg
fi

