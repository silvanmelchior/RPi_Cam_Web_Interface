name=$1
file="${name%.*}"
avconv -itsoffset -5 -i /mnt/media/"$name" -vcodec mjpeg -vframes 1 -an -f rawvideo -s 640x480 /mnt/media/thumbs/"$file".jpg
