#!/bin/bash

cd $(dirname $(readlink -f $0))

if [ $(dpkg-query -W -f='${Status}' "dialog" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  sudo apt-get install -y dialog
fi

# Terminal colors
color_red="tput setaf 1"
color_green="tput setaf 2"
color_reset="tput sgr0"
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

ASK_TO_REBOOT=0
RASPICONFIG=/boot/config.txt
MAINSCRIPT="./RPi_Cam_Web_Interface_Installer.sh"

# Version stuff moved out functions as we need it more when one time.
versionfile="./www/config.php"
version=$(cat $versionfile | grep "'APP_VERSION'" | cut -d "'" -f4)
backtitle="Copyright (c) 2014, Silvan Melchior. RPi Cam $version"

get_config_var() {
  lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
local found=false
for line in file:lines() do
  local val = line:match("^%s*"..key.."=(.*)$")
  if (val ~= nil) then
    print(val)
    found=true
    break
  end
end
if not found then
   print(0)
end
EOF
}

set_config_var() {
  lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}

do_finish() {
  if [ $ASK_TO_REBOOT -eq 1 ]; then
    dialog --yesno "Would you like to reboot now?" 5 35
    if [ $? -eq 0 ]; then # yes
      sync
      reboot
	elif [ $? -eq 1 ]; then # no
	  exec sudo $MAINSCRIPT
    fi
  fi
  exit 0
}

do_camera ()
{
  if [ ! -e /boot/start_x.elf ]; then
    dialog --msgbox "Your firmware appears to be out of date (no start_x.elf). Please update" 20 60
	exec sudo $MAINSCRIPT
  fi
  dialog --title "Raspberry Pi camera message" \
  --backtitle "$backtitle"                     \
  --extra-button --extra-label Disable         \
  --ok-label Enable                            \
  --yesno "Enable support for Raspberry Pi camera?" 5 48
  response=$?
  case $response in
    0) #echo "[Enable] key pressed."
    set_config_var start_x 1 $RASPICONFIG
    CUR_GPU_MEM=$(get_config_var gpu_mem $RASPICONFIG)
    if [ -z "$CUR_GPU_MEM" ] || [ "$CUR_GPU_MEM" -lt 128 ]; then
      set_config_var gpu_mem 128 $RASPICONFIG
    fi
    sed $RASPICONFIG -i -e "s/^startx/#startx/"
    sed $RASPICONFIG -i -e "s/^fixup_file/#fixup_file/"
	ASK_TO_REBOOT=1
	do_finish
    ;;
    1) #echo "[Cansel] key pressed."
    exec sudo $MAINSCRIPT
    ;;
    3) #echo "[Disable] key pressed."
    set_config_var start_x 0 $RASPICONFIG
    sed $RASPICONFIG -i -e "s/^startx/#startx/"
    sed $RASPICONFIG -i -e "s/^start_file/#start_file/"
    sed $RASPICONFIG -i -e "s/^fixup_file/#fixup_file/"
	ASK_TO_REBOOT=1
	do_finish
    ;;
    255) echo "[ESC] key pressed."
    exec sudo $MAINSCRIPT
    ;;
  esac
}

do_camera
exit
