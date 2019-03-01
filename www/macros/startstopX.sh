#!/bin/bash
# example start up script which converts any existing .h264 files into MP4

MACRODIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASEDIR="$( cd "$( dirname "${MACRODIR}" )" >/dev/null 2>&1 && pwd )"
mypidfile=${MACRODIR}/startstop.sh.pid
mylogfile=${BASEDIR}/scheduleLog.txt

#Check if script already running
NOW=`date +"-%Y/%m/%d %H:%M:%S-"`
if [ -f $mypidfile ]; then
        echo "${NOW} Script already running..." >> ${mylogfile}
        exit
fi
#Remove PID file when exiting
trap "rm -f -- '$mypidfile'" EXIT

echo $$ > "$mypidfile"

#Do conversion
if [ "$1" == "start" ]; then
  cd ${MACRODIR}
  cd ../media
  shopt -s nullglob
  for f in *.h264
    do
      f1=${f%.*}.mp4
        NOW=`date +"-%Y/%m/%d %H:%M:%S-"`
        echo "${NOW} Converting $f" >> ${mylogfile}
        #set -e;MP4Box -fps 25 -add $f $f1 > /dev/null 2>&1;rm $f;
        if MP4Box -fps 25 -add $f $f1; then
                NOW=`date +"-%Y/%m/%d %H:%M:%S-"`
                echo "${NOW} Conversion complete, removing $f" >> ${mylogfile}
                rm $f
        else
                NOW=`date +"-%Y/%m/%d %H:%M:%S-"`
                echo "${NOW} Error with $f" >> ${mylogfile}
        fi
    done
fi
