#!/bin/bash

file="/home/pi/vars/x" #the file where you keep your string name

r=$(cat "$file")        #the output of 'cat $file' is assigned to the $name variable
r2=$(($r+10))

if [ "$r2" -ge 220 ]; then
           r2=220
fi


echo "1="$r2 > /dev/servoblaster

echo $r2 > "$file"


