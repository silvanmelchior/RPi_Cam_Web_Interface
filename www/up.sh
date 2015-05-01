#!/bin/bash

file="/var/www/vars/y" #the file where you keep your string name

r=$(cat "$file")        #the output of 'cat $file' is assigned to the $name variable
r2=$(($r-7))

if [ "$r" -le 95 ]; then
           r2=95
fi

echo "0="$r2 > /dev/servoblaster

echo $r2 > "$file"

