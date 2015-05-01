#!/bin/bash

file="/var/www/vars/x" #the file where you keep your string name

r=$(cat "$file")        #the output of 'cat $file' is assigned to the $name variable
r2=$(($r+7))

if [ "$r2" -ge 235 ]; then
           r2=235
fi


echo "1="$r2 > /dev/servoblaster

echo $r2 > "$file"


