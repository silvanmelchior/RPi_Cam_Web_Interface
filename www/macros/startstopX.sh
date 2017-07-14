#!/bin/bash
# example start up script which converts any existing .h264 files into MP4
#Check if script already running
mypidfile=/var/www/html/macros/startstopX.sh.pid

NOW=`date +"-%Y/%m/%d %H:%M:%S-"`
if [ -f $mypidfile ]; then
        echo "${NOW} Script already running..." >> /var/www/html/scheduleLog.txt
        exit
fi
#Remove PID file when exiting
trap "rm -f -- '$mypidfile'" EXIT

echo $$ > "$mypidfile"

#Do conversion
if [ "$1" == "start" ]; then
  cd $(dirname $(readlink -f $0))
  cd ../media
  shopt -s nullglob
  for f in *.h264
    do
      f1=${f%.*}
        NOW=`date +"-%Y/%m/%d %H:%M:%S-"`
        echo "${NOW} Converting $f" >> /var/www/html/scheduleLog.txt
        #set -e;MP4Box -fps 25 -add $f $f1 > /dev/null 2>&1;rm $f;
        if MP4Box -fps 25 -add $f $f1; then
                NOW=`date +"-%Y/%m/%d %H:%M:%S-"`
                echo "${NOW} Conversion complete, removing $f" >> /var/www/html/scheduleLog.txt
                rm $f
        else
                NOW=`date +"-%Y/%m/%d %H:%M:%S-"`
                echo "${NOW} Error with $f" >> /var/www/html/scheduleLog.txt
        fi
    done
fi
