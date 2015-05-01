#!/bin/bash

file="/home/pi/vars/y" #the file where you keep your string name

r=$(cat "$file")        #the output of 'cat $file' is assigned to the $name variable
r2=$(($r-10))

if [ "$r" -le 110 ]; then
           r2=110
fi

echo "0="$r2 > /dev/servoblaster

echo $r2 > "$file"

