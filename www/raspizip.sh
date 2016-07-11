#!/bin/bash
ZIPNAME=$1
FILELIST=$2
COUNTFILE=$1.count
COUNTER=0
TOTAL=`awk 'END{print NR}' $FILELIST`

while read line         
do  
    COUNTER=$((COUNTER + 1))
    echo $COUNTER "/" $TOTAL > $COUNTFILE
    zip -0 -g -q $ZIPNAME $line
done <$FILELIST

echo "Done" > $COUNTFILE
rm -f $FILELIST