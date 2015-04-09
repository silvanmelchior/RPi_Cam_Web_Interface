#!/bin/bash
ZIPNAME=$1
FILELIST=$2
COUNTFILE=$1.count
COUNTER=0
TOTAL=`awk 'END{print NR}' $FILELIST`

while read line           
do  
    zip -q $ZIPNAME $line 
    COUNTER=$((COUNTER + 1))   
    echo $COUNTER "/" $TOTAL > $COUNTFILE 
done <$FILELIST

rm -f $COUNTFILE
rm -f $FILELIST