#!/bin/bash
# example start up script which converts any existing .h264 files into MP4
if [ "$1" == "start" ]; then
  cd $(dirname $(readlink -f $0))
  cd ../media
  shopt -s nullglob
  for f in *.h264
    do
      f1=${f%.*}
	  set -e;MP4Box -fps 25 -add $f $f1 > /dev/null 2>&1;rm $f;
    done
fi
