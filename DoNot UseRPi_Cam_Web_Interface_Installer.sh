#!/bin/bash

# Copyright (c) 2014, Silvan Melchior
# All rights reserved.

# Redistribution and use, with or without modification, are permitted provided
# that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Neither the name of the copyright holder nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Description
# This script installs a browser-interface to control the RPi Cam. It can be run
# on any Raspberry Pi with a newly installed raspbian and enabled camera-support.
#
# Edited by jfarcher to work with github
# Edited by slabua to support custom installation folder
# Additions by btidey, miraaz, gigpi 


# Configure below the folder name where to install the software to,
#  or leave empty to install to the root of the webserver.
# The folder name must be a subfolder of /var/www/ or /var/www/html/ which will be created
#  accordingly, and must not include leading nor trailing / character.
# Default upstream behaviour: RPICAMDIR="" (installs in /var/www/ or /var/www/html)

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

RASPICONFIG=/boot/config.txt

FN_WWWROOT_PORT()
{
PACKAGE=('nginx' 'apache2');
for i in "${PACKAGE[@]}"
do
  if [ $(dpkg-query -W -f='${Status}' "$i" 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    WEBSERVER="$i"
    if [ "$WEBSERVER" == "nginx" ]; then
      WWWROOT=$(sudo cat /etc/nginx/sites-enabled/default | grep "^	root" | cut -d " " -f2 | cut -d ";" -f1)
      WEBPORT=$(sudo cat /etc/nginx/sites-available/default | grep "^	listen" | cut -d " " -f2 | head -1)
      INFO_NGINX="(Nginx installed)"
    fi
    if [ "$WEBSERVER" == "apache2" ]; then
      if [ -f "/etc/apache2/sites-available/default" ]; then
        APACHEDEFAULT="/etc/apache2/sites-available/default"
      elif [ -f "/etc/apache2/sites-available/000-default.conf" ]; then
        APACHEDEFAULT="/etc/apache2/sites-available/000-default.conf"
      fi
      WWWROOT=$(sudo cat $APACHEDEFAULT | grep "DocumentRoot" | cut -d " " -f2)
      WEBPORT=$(sudo cat $APACHEDEFAULT | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
      INFO_APACHE2="(Apache2 installed)"
    fi
  fi
done
}
FN_WWWROOT_PORT

FN_INSTALLDIR()
{
source ./config.txt
if [ "$RPICAMDIR" == "" ]; then
  INSTALLDIR="$WWWROOT"
else
  INSTALLDIR="$WWWROOT/$RPICAMDIR"
fi
}
FN_INSTALLDIR

# Tedect Debian version (we not using that right now. Historical, maby we can use)
DEBVERSION=$(cat /etc/issue)
if [ "$DEBVERSION" == "Raspbian GNU/Linux 7 \n \l" ]; then
  echo "Raspbian Wheezy";
  #WWWROOT="/var/www"
elif [ "$DEBVERSION" == "Raspbian GNU/Linux 8 \n \l" ]; then
  echo "Raspbian Jessie";
  #WWWROOT="/var/www/html"
else
  echo "Unknown"
  #WWWROOT="/var/www"
fi

# -------------------------------- START/FUNCTIONS --------------------------------	
FN_STOP ()
{ # This is function stop
        sudo killall raspimjpeg
        sudo killall php
        sudo killall motion
        sudo service apache2 stop >/dev/null 2>&1
        sudo service nginx stop >/dev/null 2>&1
        dialog --title 'Stop message' --infobox 'Stopped.' 4 16 ; sleep 2
}

FN_REBOOT ()
{ # This is function reboot system
  dialog --title "You must reboot your system!" --backtitle "$backtitle" --yesno "Do you want to reboot now?" 5 33
  response=$?
    case $response in
      0) sudo reboot;;
      1) dialog --title 'Reboot message' --colors --infobox "\Zb\Z1"'Pending system changes that require a reboot!' 4 28 ; sleep 2;;
      255) dialog --title 'Reboot message' --colors --infobox "\Zb\Z1"'Pending system changes that require a reboot!' 4 28 ; sleep 2;;
    esac
}

FN_ABORT()
{
    $color_red; echo >&2 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred. Exiting..." >&2; $color_reset
    exit 1
}

FN_RPICAMDIR ()
{ 
  source ./config.txt
  
  tmpfile=$(mktemp)
  dialog  --backtitle "$backtitle" --title "Default www-root is $WWWROOT" --cr-wrap --inputbox "\
  Current install path is $WWWROOT/$RPICAMDIR
  Enter new install Subfolder if you like." 8 52 $RPICAMDIR 2>$tmpfile
			
  sel=$?
			
  RPICAMDIR=`cat $tmpfile`
  case $sel in
  0)
    sudo sed -i "s/^RPICAMDIR=.*/RPICAMDIR=\"$RPICAMDIR\"/g" ./config.txt	
  ;;
  1) source ./config.txt ;;
  255) source ./config.txt ;;
  esac

  dialog --title 'Install path' --infobox "Install path is set $WWWROOT/$RPICAMDIR" 4 48 ; sleep 3
  sudo chmod 664 ./config.txt

  if [ "$DEBUG" == "yes" ]; then
    dialog --title "FN_RPICAMDIR ./config.txt contains" --textbox ./config.txt 22 70
  fi
}

FN_APACHEPORT ()
{
  source ./config.txt
		
  if [ "$WEBPORT" == "" ]; then
    WEBPORT=$(cat $APACHEDEFAULT | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
    sudo sed -i "s/^WEBPORT=.*/WEBPORT=\"$WEBPORT\"/g" ./config.txt
  fi		
		
  tmpfile=$(mktemp)
  dialog  --backtitle "$backtitle" --title "Current Apache web server port is $WEBPORT" --inputbox "Enter new port:" 8 40 $WEBPORT 2>$tmpfile
			
  sel=$?
			
  WEBPORT=`cat $tmpfile`
  case $sel in
  0)
    sudo sed -i "s/^WEBPORT=.*/WEBPORT=\"$WEBPORT\"/g" ./config.txt	
  ;;
  1) source ./config.txt ;;
  255) source ./config.txt ;;
  esac
			
  tmpfile=$(mktemp)
  sudo awk '/NameVirtualHost \*:/{c+=1}{if(c==1){sub("NameVirtualHost \*:.*","NameVirtualHost *:'$WEBPORT'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
  sudo awk '/Listen/{c+=1}{if(c==1){sub("Listen.*","Listen '$WEBPORT'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
  sudo awk '/<VirtualHost \*:/{c+=1}{if(c==1){sub("<VirtualHost \*:.*","<VirtualHost *:'$WEBPORT'>",$0)};print}' $APACHEDEFAULT > "$tmpfile" && sudo mv "$tmpfile" $APACHEDEFAULT
  if [ ! "$RPICAMDIR" == "" ]; then
    if [ "$WEBPORT" != "80" ]; then
      sudo sed -i "s/^netcam_url.*/netcam_url\ http:\/\/localhost:$WEBPORT\/$RPICAMDIR\/cam_pic.php/g" /etc/motion/motion.conf
    else
      sudo sed -i "s/^netcam_url.*/netcam_url\ http:\/\/localhost\/$RPICAMDIR\/cam_pic.php/g" /etc/motion/motion.conf
    fi
  else
    if [ "$WEBPORT" != "80" ]; then
      sudo sed -i "s/^netcam_url.*/netcam_url\ http:\/\/localhost:$WEBPORT\/cam_pic.php/g" /etc/motion/motion.conf
    else
      sudo sed -i "s/^netcam_url.*/netcam_url\ http:\/\/localhost\/cam_pic.php/g" /etc/motion/motion.conf
    fi
  fi
  sudo chown motion:www-data /etc/motion/motion.conf
  sudo chmod 664 /etc/motion/motion.conf
  sudo service apache2 restart
}

FN_SECURE_APACHE_NO ()
{
  if [ "$DEBUG" == "yes" ]; then
    dialog --title 'FN_SECURE_APACHE_NO' --infobox 'FN_SECURE_APACHE_NO STARTED.' 4 25 ; sleep 2
  fi
  #APACHEDEFAULT="/etc/apache2/sites-available/default"
  if [ "$APACHEDEFAULT" == "/etc/apache2/sites-available/default" ]; then
    tmpfile=$(mktemp)
    sudo awk '/AllowOverride/{c+=1}{if(c==2){sub("AllowOverride.*","AllowOverride None",$0)};print}' $APACHEDEFAULT > "$tmpfile" && sudo mv "$tmpfile" $APACHEDEFAULT
  elif [ "$APACHEDEFAULT" == "/etc/apache2/sites-available/000-default.conf" ]; then	
    tmpfile=$(mktemp)
    sudo awk '/AllowOverride/{c+=1}{if(c==3){sub("AllowOverride.*","AllowOverride None",$0)};print}' /etc/apache2/apache2.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/apache2.conf
  else
    echo "$(date '+%d-%b-%Y-%H-%M') Disable security is not possible in apache conf!" >> ./error.txt
  fi	
  #sudo awk '/netcam_userpass/{c+=1}{if(c==1){sub("^netcam_userpass.*","; netcam_userpass value",$0)};print}' /etc/motion/motion.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/motion/motion.conf
  sudo sed -i "s/^netcam_userpass.*/; netcam_userpass value/g" /etc/motion/motion.conf
  sudo /etc/init.d/apache2 restart
}

FN_SECURE_APACHE ()
{ # This is function secure in config.txt file. Working only apache right now! GUI mode.
source ./config.txt

FN_SECURE_APACHE_YES ()
{
  if [ "$DEBUG" == "yes" ]; then
    dialog --title 'FN_SECURE_APACHE_YES' --infobox 'FN_SECURE_APACHE_YES STARTED.' 4 25 ; sleep 2
  fi
  #APACHEDEFAULT="/etc/apache2/sites-available/default"
  if [ "$APACHEDEFAULT" == "/etc/apache2/sites-available/default" ]; then
    tmpfile=$(mktemp)
    sudo awk '/AllowOverride/{c+=1}{if(c==2){sub("AllowOverride.*","AllowOverride All",$0)};print}' $APACHEDEFAULT > "$tmpfile" && sudo mv "$tmpfile" $APACHEDEFAULT
  #APACHEDEFAULT="/etc/apache2/sites-available/000-default.conf"
  elif [ "$APACHEDEFAULT" == "/etc/apache2/sites-available/000-default.conf" ]; then
    tmpfile=$(mktemp)
    sudo awk '/AllowOverride/{c+=1}{if(c==3){sub("AllowOverride.*","AllowOverride All",$0)};print}' /etc/apache2/apache2.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/apache2.conf
  else
    echo "$(date '+%d-%b-%Y-%H-%M') Enable security is not possible in apache conf!" >> ./error.txt
  fi 
  #sudo awk '/; netcam_userpass/{c+=1}{if(c==1){sub("; netcam_userpass.*","netcam_userpass '$user':'$passwd'",$0)};print}' /etc/motion/motion.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/motion/motion.conf
  sudo sed -i "s/^; netcam_userpass.*/netcam_userpass/g" /etc/motion/motion.conf		
  sudo sed -i "s/^netcam_userpass.*/netcam_userpass $user:$passwd/g" /etc/motion/motion.conf
  sudo htpasswd -b -c /usr/local/.htpasswd $user $passwd
  sudo /etc/init.d/apache2 restart
}

# We make missing .htacess file
if [ ! -e $WWWROOT/$RPICAMDIR/.htaccess ]; then
sudo bash -c "cat > $WWWROOT/$RPICAMDIR/.htaccess" << EOF
AuthName "RPi Cam Web Interface Restricted Area"
AuthType Basic
AuthUserFile /usr/local/.htpasswd
AuthGroupFile /dev/null
Require valid-user
EOF
sudo chown -R www-data:www-data $WWWROOT/$RPICAMDIR/.htaccess
fi

exec 3>&1

dialog                                         \
--separate-widget $'\n'                        \
--title "RPi Cam Apache Webserver Security"    \
--backtitle "$backtitle"					   \
--form ""                                      \
0 0 0                                          \
"Enable:(yes/no)" 1 1   "$security" 1 18 15 0  \
"User:"           2 1   "$user"     2 18 15 0  \
"Password:"       3 1   "$passwd"   3 18 15 0  \
2>&1 1>&3 | {
    read -r security
    read -r user
    read -r passwd

if [[ ! "$security" == "" || ! "$user" == "" || ! "$passwd" == "" ]] ; then
  sudo sed -i "s/^security=.*/security=\"$security\"/g" ./config.txt
  sudo sed -i "s/^user=.*/user=\"$user\"/g" ./config.txt
  sudo sed -i "s/^passwd=.*/passwd=\"$passwd\"/g" ./config.txt
fi
}

exec 3>&-

source ./config.txt

if [ ! "$security" == "yes" ]; then
  FN_SECURE_APACHE_NO
  sudo sed -i "s/^security=.*/security=\"no\"/g" ./config.txt
else
  FN_SECURE_APACHE_YES
fi

sudo chown motion:www-data /etc/motion/motion.conf
sudo chmod 664 /etc/motion/motion.conf
sudo chmod 664 ./config.txt
sudo service apache2 restart

if [ "$DEBUG" == "yes" ]; then
  if [ "$APACHEDEFAULT" == "/etc/apache2/sites-available/default" ]; then
    dialog --title "FN_SECURE_APACHE $APACHEDEFAULT contains" --textbox $APACHEDEFAULT 22 70
  elif [ "$APACHEDEFAULT" == "/etc/apache2/sites-available/000-default.conf" ]; then
    dialog --title "FN_SECURE_APACHE /etc/apache2/apache2.conf contains" --textbox /etc/apache2/apache2.conf 22 70    
  else
    echo "$(date '+%d-%b-%Y-%H-%M') Edit security is not possible in apache conf!"
  fi
  dialog --title "FN_SECURE_APACHE /etc/motion/motion.conf contains" --textbox /etc/motion/motion.conf 22 70
  dialog --title "FN_SECURE_APACHE ./config.txt contains" --textbox ./config.txt 22 70
fi
}
# -------------------------------- END/FUNCTIONS --------------------------------	

# AUTOSTART. We edit rc.local
FN_AUTOSTART_DISABLE ()
{
  if ! grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
    FN_CONFIGURE_MENU
  elif grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
    tmpfile=$(mktemp)
    sudo sed '/#START/,/#END/d' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
    # Remove to growing plank lines.
    sudo awk '!NF {if (++n <= 1) print; next}; {n=0;print}' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
    sudo sed -i "s/^AUTOSTART.*/AUTOSTART=\"no\"/g" ./config.txt
			  
    # Finally we set owners and permissions all files what we changed.
    sudo chown root:root /etc/rc.local
    sudo chmod 755 /etc/rc.local
    sudo chmod 664 ./config.txt
  fi	
	
  if [ "$DEBUG" == "yes" ]; then
    dialog --title "FN_AUTOSTART_DISABLE /etc/rc.local contains" --textbox /etc/rc.local 22 70
    dialog --title "FN_AUTOSTART_DISABLE ./config.txt contains" --textbox ./config.txt 22 70
  fi
}

FN_AUTOSTART_ENABLE ()
{
FN_INSTALLDIR
if grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
  FN_CONFIGURE_MENU
elif ! grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
  sudo sed -i '/exit 0/d' /etc/rc.local
sudo bash -c "cat >> /etc/rc.local" << EOF
#START RASPIMJPEG SECTION
mkdir -p /dev/shm/mjpeg
chown www-data:www-data /dev/shm/mjpeg
chmod 777 /dev/shm/mjpeg
sleep 4;su -c 'raspimjpeg > /dev/null 2>&1 &' www-data
if [ -e /etc/debian_version ]; then
  sleep 4;su -c "php $INSTALLDIR/schedule.php > /dev/null 2>&1 &" www-data
else
  sleep 4;su -s '/bin/bash' -c "php $INSTALLDIR/schedule.php > /dev/null 2>&1 &" www-data
fi
#END RASPIMJPEG SECTION

exit 0
EOF
  sudo chmod 755 /etc/rc.local
fi

sudo sed -i "s/^AUTOSTART.*/AUTOSTART=\"yes\"/g" ./config.txt
			  
# Finally we set owners and permissions all files what we changed.
sudo chown root:root /etc/rc.local
sudo chmod 755 /etc/rc.local
sudo chmod 664 ./config.txt
			  
if [ "$DEBUG" == "yes" ]; then
  dialog --title "FN_AUTOSTART_ENABLE /etc/rc.local contains" --textbox /etc/rc.local 22 70
  dialog --title "FN_AUTOSTART_ENABLE ./config.txt contains" --textbox ./config.txt 22 70
fi
}

FN_AUTOSTART ()
{	
source ./config.txt
		
if [ "$AUTOSTART" == "" ]; then
  if grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
    sudo sed -i "s/^AUTOSTART.*/AUTOSTART=\"yes\"/g" ./config.txt
  else
    sudo sed -i "s/^AUTOSTART.*/AUTOSTART=\"no\"/g" ./config.txt
  fi
fi
			
if grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
  status="\Zb\Z2Enabled\Zn"
else
  status="\Zb\Z1Disabled\Zn"
fi
		
# We look is AUTOSTART manually set.
if [[ "$AUTOSTART" == "yes" && "$status" == "Disabled" ]] ; then
  FN_AUTOSTART_ENABLE
elif [[ "$AUTOSTART" == "no" && "$status" == "Enabled" ]] ; then
  FN_AUTOSTART_DISABLE
else
  dialog --title "Curently auto start in boot time is $status" \
  --backtitle "$backtitle"                                     \
  --colors                                                     \
  --extra-button --extra-label Disable                         \
  --ok-label Enable                                            \
  --yesno "Do you want enable auto start in boot time?" 7 60
  response=$?
    case $response in
      0) FN_AUTOSTART_ENABLE;;
      1) FN_CONFIGURE_MENU;;
      3) FN_AUTOSTART_DISABLE;;
      255) FN_CONFIGURE_MENU;;
esac
fi
		
if grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
  dialog --title 'Autostart message' --colors --infobox 'Autostart \Zb\Z2Enabled.\Zn' 4 23 ; sleep 2
else
  dialog --title 'Autostart message' --colors --infobox 'Autostart \Zb\Z1Disabled.\Zn' 4 23 ; sleep 2
fi
			
# Finally we set owners and permissions all files what we changed.
sudo chown root:root /etc/rc.local
sudo chmod 755 /etc/rc.local
sudo chmod 664 ./config.txt
			
if [ "$DEBUG" == "yes" ]; then
  dialog --title "FN_AUTOSTART /etc/rc.local contains" --textbox /etc/rc.local 22 70
  dialog --title "FN_AUTOSTART ./config.txt contains" --textbox ./config.txt 22 70
fi
}

FN_STORAGE ()
{
# Do Not Change By Hand!
CURRENT_STORAGE="$WWWROOT/$RPICAMDIR/media"

if [[ -d "$CURRENT_STORAGE" && ! -L "$CURRENT_STORAGE" ]] ; then
  # We make directory for new media
  sudo mkdir -p $WWWROOT/$RPICAMDIR/storage
  sudo chown -R www-data:www-data $WWWROOT/$RPICAMDIR/storage
  # We move media to storage
  sudo mv $WWWROOT/$RPICAMDIR/media $WWWROOT/$RPICAMDIR/storage
  # We link it back to media
  sudo ln -s $WWWROOT/$RPICAMDIR/storage/media $WWWROOT/$RPICAMDIR/media
  sudo chown -R www-data:www-data $WWWROOT/$RPICAMDIR/media
  CURRENT_STORAGE="$WWWROOT/$RPICAMDIR/storage/media"
elif [[ -d "$CURRENT_STORAGE" && -L "$CURRENT_STORAGE" ]] ; then
  HYPER=$(readlink -f $CURRENT_STORAGE)
  CURRENT_STORAGE=$HYPER
else
  echo "$(date '+%d-%b-%Y-%H-%M') ERROR! Storage Folder or Link missing!" >> ./error.txt
  echo "$(date '+%d-%b-%Y-%H-%M') ERROR! Storage Folder or Link missing!"
  exit
fi
  
  tmpfile=$(mktemp)
  dialog  --backtitle "$backtitle" --title "Media Storage Path" --colors --cr-wrap --inputbox "\
  \Zb\Zu Current storage path: \Zn \Zb\Z4 $CURRENT_STORAGE \Zn
  \Zb\Zu Enter new storage location if you like. \Zn" 8 52 $CURRENT_STORAGE 2>$tmpfile
			
  sel=$?
			
  STORAGE=`cat $tmpfile`
  case $sel in
  0)
	if [ "$STORAGE" != "$CURRENT_STORAGE" ]; then
	  # We make directory for new storage location
	  sudo mkdir -p $STORAGE
	  sudo chown -R www-data:www-data $STORAGE
	  sudo unlink $WWWROOT/$RPICAMDIR/media
	  sudo ln -s $STORAGE $WWWROOT/$RPICAMDIR/media
	  sudo mv $CURRENT_STORAGE/* $STORAGE
	fi
  ;;
  1) source ./config.txt ;;
  255) source ./config.txt ;;
  esac

  dialog --title 'Storage path' --colors --infobox "\Zb\Zu Storage path is set \Zn \Zb\Z4 $STORAGE \Zn" 4 48 ; sleep 3
}

# We edit $APACHEDEFAULT
FN_APACHE_DEFAULT_INSTALL ()
{
if ! sudo grep -Fq 'cam_pic.php' $APACHEDEFAULT; then
  if [ ! "$RPICAMDIR" == "" ]; then
    sudo sed -i "s/<Directory\ \/var\/www\/.*/<Directory\ \/var\/www\/$RPICAMDIR\/>/g" $APACHEDEFAULT
  fi	
  sudo sed -i '/CustomLog\ ${APACHE_LOG_DIR}\/access.log\ combined/i \	SetEnvIf\ Request_URI\ "\/cam_pic.php$|\/status_mjpeg.php$"\ dontlog' $APACHEDEFAULT
  sudo sed -i 's/CustomLog\ ${APACHE_LOG_DIR}\/access.log.*/CustomLog\ ${APACHE_LOG_DIR}\/access.log\ common\ env=!dontlog/g' $APACHEDEFAULT
fi
}
FN_APACHE_DEFAULT_REMOVE ()
{
if sudo grep -Fq 'cam_pic.php' $APACHEDEFAULT; then
  if [ ! "$RPICAMDIR" == "" ]; then
    # We disable next row. It was for remove old rpicam. There we changed DocumentRoot. And that was revert that changes.
    #sudo sed -i 's/DocumentRoot\ \/var\/www.*/DocumentRoot\ \/var\/www/g' $APACHEDEFAULT
    sudo sed -i "s/<Directory\ \/var\/www\/$RPICAMDIR\/>/<Directory\ \/var\/www\/>/g" $APACHEDEFAULT
  fi
  sudo sed -i '/SetEnvIf\ Request_URI\ "\/cam_pic.php$|\/status_mjpeg.php$"\ dontlog/d' $APACHEDEFAULT
  sudo sed -i 's/CustomLog\ ${APACHE_LOG_DIR}\/access.log\ common\ env=!dontlog/CustomLog\ ${APACHE_LOG_DIR}\/access.log\ combined/g' $APACHEDEFAULT
fi
}

FN_MOTION ()
{
# Enable rows
strings=('netcam_url' 'on_event_start' 'on_event_end');
for i in "${strings[@]}"
do
  sudo sed -i "s/^; "$i".*/"$i"/g" /etc/motion/motion.conf
done

# Disable rows
strings=('process_id_file' 'videodevice');
for i in "${strings[@]}"
do
  sudo sed -i "s/^"$i".*/; "$i"/g" /etc/motion/motion.conf
done

# Turn off
strings=('output_pictures' 'ffmpeg_output_movies' 'ffmpeg_cap_new');
for i in "${strings[@]}"
do
  sudo sed -i "s/^"$i".*/"$i" off/g" /etc/motion/motion.conf
done

if [ "$passwd" == "" ]; then
   sudo sed -i "s/^netcam_userpass.*/; netcam_userpass value/g" /etc/motion/motion.conf		
else
   sudo sed -i "s/^; netcam_userpass.*/netcam_userpass/g" /etc/motion/motion.conf		
   sudo sed -i "s/^netcam_userpass.*/netcam_userpass $user:$passwd/g" /etc/motion/motion.conf		
fi

if [ "$RPICAMDIR" == "" ]; then
   sudo sed -i "s/^on_event_start.*/on_event_start echo -n \'1\' >\/var\/www\/html\/FIFO1/g" /etc/motion/motion.conf
   sudo sed -i "s/^on_event_end.*/on_event_end echo -n \'0\' >\/var\/www\/html\/FIFO1/g" /etc/motion/motion.conf
    if [ "$WEBPORT" != "80" ]; then
      sudo sed -i "s/^netcam_url.*/netcam_url\ http:\/\/localhost:$WEBPORT\/cam_pic.php/g" /etc/motion/motion.conf
    else
      sudo sed -i "s/^netcam_url.*/netcam_url\ http:\/\/localhost\/cam_pic.php/g" /etc/motion/motion.conf
    fi
else
   sudo sed -i "s/^on_event_start.*/on_event_start echo -n \'1\' >\/var\/www\/html\/$RPICAMDIR\/FIFO1/g" /etc/motion/motion.conf
   sudo sed -i "s/^on_event_end.*/on_event_end echo -n \'0\' >\/var\/www\/html\/$RPICAMDIR\/FIFO1/g" /etc/motion/motion.conf
    if [ "$WEBPORT" != "80" ]; then
      sudo sed -i "s/^netcam_url.*/netcam_url\ http:\/\/localhost:$WEBPORT\/$RPICAMDIR\/cam_pic.php/g" /etc/motion/motion.conf
    else
      sudo sed -i "s/^netcam_url.*/netcam_url\ http:\/\/localhost\/$RPICAMDIR\/cam_pic.php/g" /etc/motion/motion.conf
    fi
fi

  if [ ! "$RPICAMDIR" == "" ]; then
    if [ "$WEBPORT" != "80" ]; then
      sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost:$WEBPORT\/$RPICAMDIR\/cam_pic.php/g" /etc/motion/motion.conf
    else
      sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost\/$RPICAMDIR\/cam_pic.php/g" /etc/motion/motion.conf
    fi
  else
    if [ "$WEBPORT" != "80" ]; then
      sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost:$WEBPORT\/cam_pic.php/g" /etc/motion/motion.conf
    else
      sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost\/cam_pic.php/g" /etc/motion/motion.conf
    fi
  fi

sudo sed -i "s/control_port.*/control_port 6642/g" /etc/motion/motion.conf
sudo sed -i "s/^stream_port.*/stream_port 0/g" /etc/motion/motion.conf		
sudo sed -i "s/^webcam_port.*/webcam_port 0/g" /etc/motion/motion.conf
sudo sed -i "s/^event_gap 60/event_gap 3/g" /etc/motion/motion.conf
sudo sed -i "s/control_html_output.*/control_html_output off/g" /etc/motion/motion.conf

sudo chown motion:www-data /etc/motion/motion.conf
sudo chmod 664 /etc/motion/motion.conf
}

        # -------------------------------- START/File locations --------------------------------
        # List of files what We Back Up
        ##########################################
        #/etc/rc.local
        #/etc/passwd
        ##########################################
        sudo mkdir -p ./Backup/Preinstall

        #/etc/rc.local
        if [ -f "/etc/rc.local" ]; then
           if [ ! -f ./Backup/Preinstall/etc/rc.local ]; then
             sudo cp -p --parents /etc/rc.local ./Backup/Preinstall/
           fi
           echo "File /etc/rc.local ${GREEN}Exist.${NORMAL}" 
        else
           echo "$(date '+%d-%b-%Y-%H-%M') File /etc/rc.local does not exist!" >> ./error.txt
           echo "File /etc/rc.local ${RED}does Not exist!${NORMAL}"
        fi

        #/etc/passwd
        if [ -f "/etc/passwd" ]; then
           if [ ! -f ./Backup/Preinstall/etc/passwd ]; then
             sudo cp -p --parents /etc/passwd ./Backup/Preinstall/
           fi
	  echo "File /etc/passwd ${GREEN}Exist.${NORMAL}" 
        else
	  echo "$(date '+%d-%b-%Y-%H-%M') File /etc/passwd does not exist!" >> ./error.txt
	  echo "File /etc/passwd ${RED}does Not exist!${NORMAL}"
        fi

	# -------------------------------- END/File locations --------------------------------
		
	# -------------------------------- START/config.txt --------------------------------
	# Config options located in ./config.txt. In first run script makes that file for you.
	if [ ! -e ./config.txt ]; then
	  sudo echo "#This is config file for main installer. Put any extra options in here." > ./config.txt
	  sudo echo "" >> ./config.txt
	fi

	# We enable DEBUG installer script
	if ! grep -Fq "DEBUG=" ./config.txt; then
	  sudo echo "# Enable or disable DEBUG for installer script" >> ./config.txt
	  sudo echo "DEBUG=\"no\"" >> ./config.txt
	  sudo echo "" >> ./config.txt
	fi

	# RPICAMDIR
	if ! grep -Fq "RPICAMDIR=" ./config.txt; then
	  sudo echo "# Rpicam install directory" >> ./config.txt
	  sudo echo "RPICAMDIR=\"\"" >> ./config.txt
	  sudo echo "" >> ./config.txt
	fi

	# AUTOSTART
	if ! grep -Fq "AUTOSTART=" ./config.txt; then
	  sudo echo "# Enable or disable AUTOSTART" >> ./config.txt
	  sudo echo "AUTOSTART=\"\"" >> ./config.txt
	  sudo echo "" >> ./config.txt
	fi

	# SECURITY
	if ! grep -Fq "security=" ./config.txt; then
	  sudo echo "# Webserver security" >> ./config.txt
	  sudo echo "security=\"no\"" >> ./config.txt
	  sudo echo "user=\"\"" >> ./config.txt
	  sudo echo "passwd=\"\"" >> ./config.txt
	  sudo echo "" >> ./config.txt
	fi

	sudo chmod 664 ./config.txt
	source ./config.txt  
	# -------------------------------- END/config.txt --------------------------------

# Start and Stop without GUI mode.
case "$1" in
  start)
        FN_STOP
        sudo mkdir -p /dev/shm/mjpeg
        sudo chown www-data:www-data /dev/shm/mjpeg
        sudo chmod 777 /dev/shm/mjpeg
        sleep 1;sudo su -c 'raspimjpeg > /dev/null &' www-data
        if [ -e /etc/debian_version ]; then
          sleep 1;sudo su -c "php $WWWROOT/$RPICAMDIR/schedule.php > /dev/null &" www-data
        else
          sleep 1;sudo su -c '/bin/bash' -c "php $WWWROOT/$RPICAMDIR/schedule.php > /dev/null &" www-data
        fi

        dialog --title 'Start message' --infobox 'Started.' 4 16 ; sleep 2
	exit
        ;;

  stop)
        FN_STOP
	exit
        ;;  
esac

# Version stuff moved out functions as we need it more when one time.
versionfile="./www/config.php"
version=$(cat $versionfile | grep "'APP_VERSION'" | cut -d "'" -f4)
backtitle="Copyright (c) 2014, Silvan Melchior. RPi Cam $version"

FN_MENU_INSTALLER ()
{
# We using only "raspimjpeg" right now, but we need extracted values for future development.
process=('raspimjpeg' 'php' 'motion'); 
for i in "${process[@]}"
  do
    ps cax | grep $i > /dev/null
    if [ $? -eq 0 ]; then
      echo "process_$i="started"" >> tmp_status
    else
      echo "process_$i="stopped"" >> tmp_status
    fi
done
  
source ./tmp_status

# Do not put values here! Its for reset variables after function reloaded.
stopped_rpicam=""
started_rpicam=""

if [ "$process_raspimjpeg" == "started" ] ; then
  started_rpicam="(started)"
else
  stopped_rpicam="(stopped)"
fi
rm ./tmp_status	
	
cmd=(dialog --backtitle "$backtitle" --title "RPi Cam Web Interface Installer" --colors --menu "Select your option:$WEBSERVER" 13 76 16)

options=("1 install" "\Zb\ZuInstall\Zn (\Zb\ZuApache\Zn web server based) \Zb\Z2$INFO_APACHE2\Zn"
         "2 install_nginx" "\Zb\ZuInstall\Zn (\Zb\ZuNginx\Zn web server based) \Zb\Z2$INFO_NGINX\Zn"
         "3 configure" "\Zb\Z1Configure\Zn RPi Cam (After install)"
         "4 start" "\Zb\ZuStart\Zn RPi Cam \Zb\Z2$started_rpicam"
         "5 stop" "\Zb\ZuStop\Zn RPi Cam \Zb\Z1$stopped_rpicam"
         "6 remove" "\Zb\ZuRemove\Zn RPi Cam")

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
  case $choice in

  install)
        dialog --title 'Basic Install message' --colors --infobox "\Zb\Z1Notice!\Zn Configure you settings after install using \Zb\Z1\"configure\"\Zn option." 5 43 ; sleep 4
        sudo killall raspimjpeg
        sudo apt-get install -y apache2 php5 php5-cli libapache2-mod-php5 gpac motion zip libav-tools usbmount
        sudo a2enmod authz_groupfile
        sudo service apache2 restart
		
        # -------------------------------- START/File locations --------------------------------
        # List of files what We Back Up
        ##########################################
        #/etc/apache2/sites-available/default
        #/etc/apache2/sites-available/000-default.conf
        #/etc/apache2/apache2.conf
        #/etc/apache2/ports.conf
        #/etc/motion/motion.conf
        # Directories
        #/etc/apache2/conf.d
        #/etc/apache2/conf-available
        ##########################################
        #/etc/apache2/sites-available/default
        #/etc/apache2/sites-available/000-default.conf
        if [ -f "/etc/apache2/sites-available/default" ]; then
          if [ ! -f ./Backup/Preinstall/etc/apache2/sites-available/default ]; then
            sudo cp -p --parents /etc/apache2/sites-available/default ./Backup/Preinstall/
          fi
          APACHEDEFAULT="/etc/apache2/sites-available/default"
          echo "File $APACHEDEFAULT ${GREEN}Exist.${NORMAL}"
        elif [ -f "/etc/apache2/sites-available/000-default.conf" ]; then
          if [ ! -f ./Backup/Preinstall/etc/apache2/sites-available/000-default.conf ]; then
            sudo cp -p --parents /etc/apache2/sites-available/000-default.conf ./Backup/Preinstall/
          fi
          APACHEDEFAULT="/etc/apache2/sites-available/000-default.conf"
          echo "File $APACHEDEFAULT ${GREEN}Exist.${NORMAL}"  
        else
          echo "$(date '+%d-%b-%Y-%H-%M') File $APACHEDEFAULT does not exist!" >> ./error.txt
          echo "File $APACHEDEFAULT ${RED}does Not exist!{NORMAL}"
        fi
        #/etc/apache2/apache2.conf
        if [ -f "/etc/apache2/apache2.conf" ]; then
          if [ ! -f ./Backup/Preinstall/etc/apache2/apache2.conf ]; then
            sudo cp -p --parents /etc/apache2/apache2.conf ./Backup/Preinstall/
          fi
          echo "File /etc/apache2/apache2.conf ${GREEN}Exist.${NORMAL}" 
        else
          echo "$(date '+%d-%b-%Y-%H-%M') File /etc/apache2/apache2.conf does not exist!" >> ./error.txt
          echo "File /etc/apache2/apache2.conf ${RED}does Not exist!${NORMAL}"
        fi
        #/etc/apache2/ports.conf
        if [ -f "/etc/apache2/ports.conf" ]; then
          if [ ! -f ./Backup/Preinstall/etc/apache2/ports.conf ]; then
            sudo cp -p --parents /etc/apache2/ports.conf ./Backup/Preinstall/
          fi
          echo "File /etc/apache2/ports.conf ${GREEN}Exist.${NORMAL}" 
        else
          echo "$(date '+%d-%b-%Y-%H-%M') File /etc/apache2/ports.conf does not exist!" >> ./error.txt
          echo "File /etc/apache2/ports.conf ${RED}does Not exist!${NORMAL}"
        fi
        #/etc/motion/motion.conf
        if [ -f "/etc/motion/motion.conf" ]; then
          if [ ! -f ./Backup/Preinstall/etc/motion/motion.conf ]; then
            sudo cp -p --parents /etc/motion/motion.conf ./Backup/Preinstall/
          fi
          echo "File /etc/motion/motion.conf ${GREEN}Exist.${NORMAL}" 
        else
          echo "$(date '+%d-%b-%Y-%H-%M') File /etc/motion/motion.conf does not exist!" >> ./error.txt
          echo "File /etc/motion/motion.conf ${RED}does Not exist!${NORMAL}"
        fi
        # Directories
        #/etc/apache2/conf.d
        #/etc/apache2/conf-available
        if [ -d "/etc/apache2/conf.d" ]; then
          APACHELOG="/etc/apache2/conf.d"
          echo "Directory $APACHELOG ${GREEN}Exist.${NORMAL}"
        elif [ -d "/etc/apache2/conf-available" ]; then
          APACHELOG="/etc/apache2/conf-available"
          echo "Directory $APACHELOG ${GREEN}Exist.${NORMAL}"   
        else
          echo "$(date '+%d-%b-%Y-%H-%M') APACHELOG does not exist!" >> ./error.txt
          echo "Directory APACHELOG ${RED}does Not exist!${NORMAL}"
        fi
        # -------------------------------- END/File locations --------------------------------
        # -------------------------------- START/config.txt --------------------------------
        # WEBPORT
        #cat 000-default.conf | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1
        if ! grep -Fq "WEBPORT=" ./config.txt; then
          WEBPORT=$(sudo cat $APACHEDEFAULT | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
          sudo echo "# Web server port" >> ./config.txt
          sudo echo "WEBPORT=\"$WEBPORT\"" >> ./config.txt
          sudo echo "" >> ./config.txt
	    fi
	    if [ "$WEBPORT" == "" ]; then
          WEBPORT=$(sudo cat $APACHEDEFAULT | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
          sudo sed -i "s/^WEBPORT=.*/WEBPORT=\"$WEBPORT\"/g" ./config.txt
	    fi
		
	sudo chmod 664 ./config.txt
	source ./config.txt 
	# -------------------------------- END/config.txt --------------------------------
	
	# We need find wwwroot after apache2 installed
	FN_WWWROOT_PORT
        if [ "$WWWROOT" == "/var/www/html" ]; then
          sudo sed -i "s/^www-data:x.*/www-data:x:33:33:www-data:\/var\/www\/html:\/bin\/sh/g" /etc/passwd
        fi
		
	FN_RPICAMDIR
		
	FN_AUTOSTART_ENABLE
		
        sudo mkdir -p $WWWROOT/$RPICAMDIR/media
        sudo cp -r www/* $WWWROOT/$RPICAMDIR/
        if [ -e $WWWROOT/$RPICAMDIR/index.html ]; then
          sudo cp -p --parents $WWWROOT/$RPICAMDIR/index.html ./Backup/Preinstall/
          sudo mv $WWWROOT/$RPICAMDIR/index.html $WWWROOT/$RPICAMDIR/index.html.bak
        fi
        sudo chown -R www-data:www-data $WWWROOT/$RPICAMDIR
        
        if [ ! -e $WWWROOT/$RPICAMDIR/FIFO ]; then
          sudo mknod $WWWROOT/$RPICAMDIR/FIFO p
        fi
        sudo chmod 666 $WWWROOT/$RPICAMDIR/FIFO
        
        if [ ! -e $WWWROOT/$RPICAMDIR/FIFO1 ]; then
          sudo mknod $WWWROOT/$RPICAMDIR/FIFO1 p
        fi
        sudo chmod 666 $WWWROOT/$RPICAMDIR/FIFO1
        sudo chmod 755 $WWWROOT/$RPICAMDIR/raspizip.sh

        if [ ! -e $WWWROOT/$RPICAMDIR/cam.jpg ]; then
          sudo ln -sf /run/shm/mjpeg/cam.jpg $WWWROOT/$RPICAMDIR/cam.jpg
        fi
        if [ -e $WWWROOT/$RPICAMDIR/status_mjpeg.txt ]; then
          sudo rm $WWWROOT/$RPICAMDIR/status_mjpeg.txt
        fi
        sudo ln -sf /run/shm/mjpeg/status_mjpeg.txt $WWWROOT/$RPICAMDIR/status_mjpeg.txt

        FN_APACHE_DEFAULT_INSTALL

        sudo cp etc/apache2/conf.d/other-vhosts-access-log $APACHELOG/other-vhosts-access-log
        sudo chmod 644 $APACHELOG/other-vhosts-access-log

        sudo cp etc/sudoers.d/RPI_Cam_Web_Interface /etc/sudoers.d/
        sudo chmod 440 /etc/sudoers.d/RPI_Cam_Web_Interface

        sudo cp -r bin/raspimjpeg /opt/vc/bin/
        sudo chmod 755 /opt/vc/bin/raspimjpeg
        if [ ! -e /usr/bin/raspimjpeg ]; then
          sudo ln -s /opt/vc/bin/raspimjpeg /usr/bin/raspimjpeg
        fi

        if [ "$WWWROOT" == "/var/www" ]; then
          if [ "$RPICAMDIR" == "" ]; then
            sudo cat etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
          else
            sudo sed -e "s/www/www\/$RPICAMDIR/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
          fi
        elif [ "$WWWROOT" == "/var/www/html" ]; then
          if [ "$RPICAMDIR" == "" ]; then
            sudo sed -e "s/www/www\/html/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
          else
            sudo sed -e "s/www/www\/html\/$RPICAMDIR/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
          fi		
        fi
		
        if [ `cat /proc/cmdline |awk -v RS=' ' -F= '/boardrev/ { print $2 }'` == "0x11" ]; then
          sudo sed -i "s/^camera_num 0/camera_num 1/g" etc/raspimjpeg/raspimjpeg
        fi
        if [ -e /etc/raspimjpeg ]; then
          $color_green; echo "Your custom raspimjpeg backed up at /etc/raspimjpeg.bak"; $color_reset
          sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
        fi
        sudo cp -r etc/raspimjpeg/raspimjpeg /etc/
        sudo chmod 644 /etc/raspimjpeg
        if [ ! -e $WWWROOT/$RPICAMDIR/raspimjpeg ]; then
          sudo ln -s /etc/raspimjpeg $WWWROOT/$RPICAMDIR/raspimjpeg
        fi

        FN_MOTION
        : '
        # We commented old Whreezy way out. If we not get complaints FN_MOTION not working in Whreezy we can remove old way.
        if [ "$WWWROOT" == "/var/www" ]; then
          if [ "$RPICAMDIR" == "" ]; then
            sudo cat etc/motion/motion.conf.1 > etc/motion/motion.conf
        else
          sudo sed -e "s/www/www\/$RPICAMDIR/" etc/motion/motion.conf.1 > etc/motion/motion.conf
          sudo sed -i "s/^netcam_url.*/netcam_url http:\/\/localhost\/$RPICAMDIR\/cam_pic.php/g" etc/motion/motion.conf
          sudo cp -r etc/motion/motion.conf /etc/motion/
        fi
        elif [ "$WWWROOT" == "/var/www/html" ]; then
          FN_MOTION		
        fi
        '
		
        sudo usermod -a -G video www-data
        if [ -e $WWWROOT/$RPICAMDIR/uconfig ]; then
          sudo chown www-data:www-data $WWWROOT/$RPICAMDIR/uconfig
        fi
        
        if [ ! "$RPICAMDIR" == "" ]; then
          sudo sed -i "s/www\//www\/$RPICAMDIR\//g" $WWWROOT/$RPICAMDIR/schedule.php
        fi

        sudo chown motion:www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf
        sudo chown -R www-data:www-data $WWWROOT/$RPICAMDIR

        dialog --title 'Install message' --infobox 'Installer finished.' 4 25 ; sleep 2
        FN_REBOOT
        ;;

  install_nginx)
        dialog --title 'Basic Install message' --colors --infobox "\Zb\Z1Notice!\Zn Configure you settings after install using \Zb\Z1\"configure\"\Zn option." 5 43 ; sleep 4
        sudo killall raspimjpeg
        sudo apt-get install -y nginx php5-fpm php5-cli php5-common php-apc gpac motion zip libav-tools

	# -------------------------------- START/File locations --------------------------------
	# List of files what We Back Up
	##########################################
	#/etc/nginx/sites-available/default
	##########################################
        #/etc/nginx/sites-available/default
        if [ -f "/etc/nginx/sites-available/default" ]; then
           if [ ! -f ./Backup/Preinstall/etc/nginx/sites-available/default ]; then
             sudo cp -p --parents /etc/nginx/sites-available/default ./Backup/Preinstall/
           fi
           echo "File etc/nginx/sites-available/default ${GREEN}Exist.${NORMAL}" 
        else
           echo "$(date '+%d-%b-%Y-%H-%M') File etc/nginx/sites-available/default does not exist!" >> ./error.txt
           echo "File etc/nginx/sites-available/default ${RED}does Not exist!${NORMAL}"
        fi
		
	    FN_WWWROOT_PORT
		
        if [ "$WWWROOT" == "/var/www/html" ]; then
          sudo sed -i "s/^www-data:x.*/www-data:x:33:33:www-data:\/var\/www\/html:\/bin\/sh/g" /etc/passwd
        fi
		
        FN_RPICAMDIR
        sudo mkdir -p $WWWROOT/$RPICAMDIR/media
        sudo cp -r www/* $WWWROOT/$RPICAMDIR/
        if [ -e $WWWROOT/$RPICAMDIR/index.html ]; then
          sudo rm $WWWROOT/$RPICAMDIR/index.html
        fi
        sudo chown -R www-data:www-data $WWWROOT/$RPICAMDIR

        if [ ! -e $WWWROOT/$RPICAMDIR/FIFO ]; then
          sudo mknod $WWWROOT/$RPICAMDIR/FIFO p
        fi
        sudo chmod 666 $WWWROOT/$RPICAMDIR/FIFO

        if [ ! -e $WWWROOT/$RPICAMDIR/FIFO1 ]; then
          sudo mknod $WWWROOT/$RPICAMDIR/FIFO1 p
        fi
        sudo chmod 666 $WWWROOT/$RPICAMDIR/FIFO1
        sudo chmod 755 $WWWROOT/$RPICAMDIR/raspizip.sh

        if [ ! -e $WWWROOT/$RPICAMDIR/cam.jpg ]; then
          sudo ln -sf /run/shm/mjpeg/cam.jpg $WWWROOT/$RPICAMDIR/cam.jpg
        fi
        if [ -e $WWWROOT/$RPICAMDIR/status_mjpeg.txt ]; then
           sudo rm $WWWROOT/$RPICAMDIR/status_mjpeg.txt
        fi
        sudo ln -sf /run/shm/mjpeg/status_mjpeg.txt $WWWROOT/$RPICAMDIR/status_mjpeg.txt

        if [ "$RPICAMDIR" == "" ]; then
          sudo cat etc/nginx/sites-available/rpicam.1 > etc/nginx/sites-available/rpicam
        else
          sudo sed -e "s:root $WWWROOT;:root $WWWROOT/$RPICAMDIR;:g" etc/nginx/sites-available/rpicam.1 > etc/nginx/sites-available/rpicam
        fi
        sudo cp -r etc/nginx/sites-available/rpicam /etc/nginx/sites-available/rpicam
        sudo chmod 644 /etc/nginx/sites-available/rpicam


        if [ ! -e /etc/nginx/sites-enabled/rpicam ]; then
          sudo ln -s /etc/nginx/sites-available/rpicam /etc/nginx/sites-enabled/rpicam
        fi

        # Update nginx main config file
        sudo sed -i "s/worker_processes 4;/worker_processes 2;/g" /etc/nginx/nginx.conf
        sudo sed -i "s/worker_connections 768;/worker_connections 128;/g" /etc/nginx/nginx.conf
        sudo sed -i "s/gzip on;/gzip off;/g" /etc/nginx/nginx.conf
        if ["$NGINX_DISABLE_LOGGING"]; then
            sudo sed -i "s:access_log /var/log/nginx/nginx/access.log;:access_log /dev/null;:g" /etc/nginx/nginx.conf
        fi

        # Configure php-apc
        sudo sh -c "echo \"cgi.fix_pathinfo = 0;\" >> /etc/php5/fpm/php.ini"
        sudo cp etc/php5/apc.ini /etc/php5/conf.d/20-apc.ini
        sudo chmod 644 /etc/php5/conf.d/20-apc.ini

        sudo cp etc/sudoers.d/RPI_Cam_Web_Interface /etc/sudoers.d/
        sudo chmod 440 /etc/sudoers.d/RPI_Cam_Web_Interface

        sudo cp -r bin/raspimjpeg /opt/vc/bin/
        sudo chmod 755 /opt/vc/bin/raspimjpeg
        if [ ! -e /usr/bin/raspimjpeg ]; then
          sudo ln -s /opt/vc/bin/raspimjpeg /usr/bin/raspimjpeg
        fi

        if [ "$RPICAMDIR" == "" ]; then
          sudo cat etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
        else
          sudo sed -e "s/www/www\/$RPICAMDIR/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
        fi
        if [ `cat /proc/cmdline |awk -v RS=' ' -F= '/boardrev/ { print $2 }'` == "0x11" ]; then
          sed -i "s/^camera_num 0/camera_num 1/g" etc/raspimjpeg/raspimjpeg
        fi
        if [ -e /etc/raspimjpeg ]; then
          $color_green; echo "Your custom raspimjpeg backed up at /etc/raspimjpeg.bak"; $color_reset
          sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
        fi
        sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
        sudo cp -r etc/raspimjpeg/raspimjpeg /etc/
        sudo chmod 644 /etc/raspimjpeg
        if [ ! -e $WWWROOT/$RPICAMDIR/raspimjpeg ]; then
          sudo ln -s /etc/raspimjpeg $WWWROOT/$RPICAMDIR/raspimjpeg
        fi

        FN_AUTOSTART

        if [ "$RPICAMDIR" == "" ]; then
          sudo cat etc/motion/motion.conf.1 > etc/motion/motion.conf
        else
          sudo sed -e "s/www/www\/$RPICAMDIR/" etc/motion/motion.conf.1 > etc/motion/motion.conf
          sudo sed -i "s/^netcam_url.*/netcam_url http:\/\/localhost\/$RPICAMDIR\/cam_pic.php/g" etc/motion/motion.conf
        fi
        sudo cp -r etc/motion/motion.conf /etc/motion/
        sudo usermod -a -G video www-data
        if [ -e $WWWROOT/$RPICAMDIR/uconfig ]; then
          sudo chown www-data:www-data $WWWROOT/$RPICAMDIR/uconfig
        fi
        
        if [ ! "$RPICAMDIR" == "" ]; then
          sudo sed -i "s/www\//www\/$RPICAMDIR\//g" $WWWROOT/$RPICAMDIR/schedule.php
        fi
        sudo chown motion:www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf
        sudo chown -R www-data:www-data $WWWROOT/$RPICAMDIR

        dialog --title 'Install message' --infobox 'Installer finished.' 4 25 ; sleep 2
        FN_REBOOT
        ;;

  configure)
        FN_WWWROOT_PORT
        FN_CONFIGURE_MENU ()
        {
	CAMERA=$(sudo cat $RASPICONFIG | grep "start_x" | cut -d "=" -f2)
	if [ $CAMERA -eq 1 ]; then
	  CAMSTATUS="\Zb\Z2(Enabled)"
	elif [ $CAMERA -eq 0 ]; then
	  CAMSTATUS="\Zb\Z1(Disabled)"
	fi
		
        if grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
          AUTOSTART="\Zb\Z2(Enabled)"
        else
          AUTOSTART="\Zb\Z1(Disabled)"
        fi	

        if [ "$APACHEDEFAULT" == "/etc/apache2/sites-available/default" ]; then
          TMP_SECURITY=$(sudo awk '/AllowOverride/ {i++}i==2{print $2; exit}' $APACHEDEFAULT)
        elif [ "$APACHEDEFAULT" == "/etc/apache2/sites-available/000-default.conf" ]; then
          TMP_SECURITY=$(sudo awk '/AllowOverride/ {i++}i==3{print $2; exit}' /etc/apache2/apache2.conf)  
        fi
        if [ "$TMP_SECURITY" == "All" ]; then
          SECURITY="\Zb\Z2(Enabled)"
        elif [ "$TMP_SECURITY" == "None" ]; then
          SECURITY="\Zb\Z1(Disabled)"
        else
          SECURITY="\Zb\Z1(ERROR!)"
        fi
        	
        cmd=(dialog --backtitle "$backtitle" --title "RPi Cam Web Interface Configurator" --colors --menu "Select your option:" 16 76 16)
        options=(
            "1 update" "\Zb\ZuUpdate\Zn RPi Cam installer"
            "2 upgrade" "\Zb\ZuUpgrade\Zn RPi Cam"
            "3 apache_security" "Change \Zb\ZuApache\Zn web server \Zb\Zusecurity\Zn $SECURITY" 
            "4 apache_port" "Change \Zb\ZuApache\Zn web server \Zb\Zuport\Zn \Zb\Z2($WEBPORT)"
            "5 autostart" "RPi Cam \Zb\ZuAutostart\Zn \Zb\ZuEnable/Disable\Zn $AUTOSTART"
            "6 camera" "\Zb\ZuEnable/Disable\Zn Raspberry Pi \Zb\Zucamera\Zn $CAMSTATUS"
            "7 storage" "RPi Cam \Zb\ZuStorage location\Zn"
            "8 backup_restore" "RPi Cam \Zb\ZuBackup\Zn or Restore"
            "9 debug" "Run RPi Cam with \Zb\Zudebug\Zn mode"
            )
        choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choices" ]]; then
          for choice in $choices
          do
            case $choice in
             update)
                trap 'FN_ABORT' 0
                set -e
                remote=$(
                    git ls-remote -h origin master |
                    awk '{print $1}'
                )
                local=$(git rev-parse HEAD)
                printf "Local : %s\nRemote: %s\n" $local $remote
                if [[ $local == $remote ]]; then
                  dialog --title 'Update message' --infobox 'Commits match. Nothing update.' 4 35 ; sleep 2
                else
                  dialog --title 'Update message' --infobox "Commits don't match. We update." 4 35 ; sleep 2
                  git pull origin master
                fi
                trap : 0
                dialog --title 'Update message' --infobox 'Update finished.' 4 20 ; sleep 2
                # We call updated script
                SCRIPT="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
                ./$SCRIPT
                ;;
             upgrade)
                sudo killall raspimjpeg
                if [ $(dpkg-query -W -f='${Status}' "zip" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
                  sudo apt-get install -y zip
                fi
                sudo cp -r bin/raspimjpeg /opt/vc/bin/
                sudo chmod 755 /opt/vc/bin/raspimjpeg
                sudo cp -r www/* $WWWROOT/$RPICAMDIR/
                if [ ! -e $WWWROOT/$RPICAMDIR/raspimjpeg ]; then
                  sudo ln -s /etc/raspimjpeg $WWWROOT/$RPICAMDIR/raspimjpeg
                fi
                sudo chmod 755 $WWWROOT/$RPICAMDIR/raspizip.sh
                dialog --title 'Upgrade message' --infobox 'Upgrade finished.' 4 20 ; sleep 2
                FN_CONFIGURE_MENU
                ;;
             apache_security)
                FN_SECURE_APACHE
                dialog --title 'Apache web security message' --infobox "Apache web security changed." 4 23 ; sleep 2
                FN_CONFIGURE_MENU
                ;;
             apache_port)
                FN_APACHEPORT
                dialog --title 'Apache web port message' --infobox "Apache web port: $webport." 4 23 ; sleep 2
                FN_CONFIGURE_MENU
                ;;
			 autostart)
                FN_AUTOSTART
                FN_CONFIGURE_MENU
                ;;
			 camera)
                exec sudo ./cam.sh
             ;;
             storage)
                FN_STORAGE
                dialog --title 'Storage message' --infobox 'Changed storage location.' 4 23 ; sleep 2
                FN_CONFIGURE_MENU
                ;;
             backup_restore)
                FN_BACKUP () 
                {
                  BACKUPDIR="$(date '+%d-%b-%Y-%H-%M')"
                  sudo mkdir -p ./Backup/$BACKUPDIR
                  sudo cp ./config.txt ./Backup/$BACKUPDIR
                  sudo cp /etc/motion/motion.conf ./Backup/$BACKUPDIR
                  sudo cp /etc/raspimjpeg ./Backup/$BACKUPDIR				
                  if [ ! "$RPICAMDIR" == "" ]; then
                    sudo cp $WWWROOT/$RPICAMDIR/uconfig ./Backup/$BACKUPDIR
                  else
                    sudo cp $WWWROOT/uconfig ./Backup/$BACKUPDIR
                  fi
                }
				
                FN_RESTORE () 
                {
                  sudo cp $ANSW/config.txt ./config.txt
                  sudo cp $ANSW/motion.conf /etc/motion/motion.conf
                  sudo cp $ANSW/raspimjpeg /etc/raspimjpeg
                  if [ ! "$RPICAMDIR" == "" ]; then
                    sudo cp $ANSW/uconfig $WWWROOT/$RPICAMDIR/uconfig
                  else
                    sudo cp $ANSW/uconfig $WWWROOT/uconfig
                  fi
                }
				
                FN_REMOVE_BACKUP ()
                {
                  let i=0
                  W=()
                  while read -r line; do
                    let i=$i+1
                    W+=($i "$line")
                  done < <( ls -1d ./Backup/*/ )
                  FILE=$(dialog --title "List Directorys of Backup ./Backup" --backtitle "$backtitle" --colors --menu "Chose Backup what you want to \Zb\Z1remove\Zn?" 24 80 17 "${W[@]}" 3>&2 2>&1 1>&3)
                  if [ "$FILE" == "" ]; then
                    FN_BACKUP_RESTORE_MENU
                  else
                    clear
                    if [ $? -eq 0 ]; then # Exit with OK
                      ANSW=$(readlink -f $(ls -1d ./Backup/*/ | sed -n "`echo "$FILE p" | sed 's/ //'`"))
                      sudo rm -r $ANSW
                      FN_REMOVE_BACKUP
                    fi
                  fi
                }
				  
                FN_RESTORE_BACKUP ()
                {
                  let i=0
                  W=()
                  while read -r line; do
                    let i=$i+1
                    W+=($i "$line")
                  done < <( ls -1d ./Backup/*/ )
                  FILE=$(dialog --title "List Directorys of Backup ./Backup" --backtitle "$backtitle" --colors --menu "Chose Backup what you want to \Zb\Z5restore\Zn?" 24 80 17 "${W[@]}" 3>&2 2>&1 1>&3)
                  if [ "$FILE" == "" ]; then
                    FN_BACKUP_RESTORE_MENU
                  else
                    clear
                    if [ $? -eq 0 ]; then # Exit with OK
                      ANSW=$(readlink -f $(ls -1d ./Backup/*/ | sed -n "`echo "$FILE p" | sed 's/ //'`"))
                      FN_RESTORE
                      dialog --title 'Restore message' --colors --infobox "Restored \Zb\Z5$ANSW." 4 80 ; sleep 3
                      FN_CONFIGURE_MENU
                    fi
                  fi
                }
				
                FN_BACKUP_RESTORE_MENU ()
                {
                  dialog --title "Backup or Restore message" \
                  --backtitle "$backtitle"                   \
                  --help-button --help-label "Remove backup" \
                  --extra-button --extra-label Restore       \
                  --ok-label Backup                          \
                  --yesno "Backup or Restore your RPi Cam config files." 5 68
                  response=$?
                  case $response in
                    0) #echo "[Backup] key pressed."
                      FN_BACKUP
                      dialog --title 'Backup message' --colors --infobox "Backup \Zb\Z5$BACKUPDIR\Zn done." 4 40 ; sleep 3
                      FN_CONFIGURE_MENU
                    ;;
                    1) #echo "[Cansel] key pressed."
                      FN_CONFIGURE_MENU
                    ;;
                    2) #echo "[Remove backup] key pressed."
                      FN_REMOVE_BACKUP
                    ;;
                    3) #echo "[Restore] key pressed."
                      FN_RESTORE_BACKUP
                    ;;
                    255) #echo "[ESC] key pressed."
                      FN_CONFIGURE_MENU
                    ;;
                  esac
                }
                FN_BACKUP_RESTORE_MENU
             ;;
                
             debug)
                FN_STOP
                sudo mkdir -p /dev/shm/mjpeg
                sudo chown www-data:www-data /dev/shm/mjpeg
                sudo chmod 777 /dev/shm/mjpeg
                sleep 1;sudo su -c 'raspimjpeg &' www-data
                if [ -e /etc/debian_version ]; then
                  sleep 1;sudo sudo su -c "php $WWWROOT/$RPICAMDIR/schedule.php &" www-data
                else
                  sleep 1;sudo su -c '/bin/bash' -c "php $WWWROOT/$RPICAMDIR/schedule.php &" www-data
                fi        
                $color_red; echo "Started with debug"; $color_reset
             ;;
			
            esac
            done
        else
          FN_MENU_INSTALLER
        fi
        }

	# This is trap if webserver not installed.
        TESTVAR="$WEBSERVER"
        VAR()
        {
        if [ ${TESTVAR[@]} ]; then
	 FN_CONFIGURE_MENU
        else
        dialog --title 'Install message' --colors --infobox 'Please \Zb\Z1Install\Zn Rpicam first!' 4 25 ; sleep 2
        FN_MENU_INSTALLER
        fi
        }
        VAR		
        ;;

  start)
        FN_STOP
        sudo mkdir -p /dev/shm/mjpeg
        sudo chown www-data:www-data /dev/shm/mjpeg
        sudo chmod 777 /dev/shm/mjpeg
        sleep 1;sudo su -c 'raspimjpeg > /dev/null &' www-data
        if [ -e /etc/debian_version ]; then
          sleep 1;sudo su -c "php $WWWROOT/$RPICAMDIR/schedule.php > /dev/null &" www-data
        else
          sleep 1;sudo su -c '/bin/bash' -c "php $WWWROOT/$RPICAMDIR/schedule.php > /dev/null &" www-data
        fi
        
        dialog --title 'Start message' --infobox 'Started.' 4 16 ; sleep 2
        FN_MENU_INSTALLER
        ;;
        
  stop)
        FN_STOP
        FN_MENU_INSTALLER
        ;;

  remove)
        FN_WWWROOT_PORT
        FN_STOP
 
    FN_LIGHT ()
    {
      FN_INSTALLDIR
      # Trap. Security reason. If we not find installdir we abort and not start remove whole system!
      if [ "$INSTALLDIR" == "" ]; then
	echo "$(date '+%d-%b-%Y-%H-%M') Install directory missing! Aborted!" >> ./error.txt
        echo "Install directory missing! ${RED}Aborted!${NORMAL}"
        FN_MENU_INSTALLER
      fi
	  
      dialog --title "Backup media?" --backtitle "$backtitle" --yesno "Do you want backup media into you home directory?" 5 33
      response=$?
        case $response in
          0) # echo yes
	    if [ ! -d ~/media ]; then
              mkdir ~/media
            fi
	    sudo mv $INSTALLDIR/media ~/media
	      ;;
          1)
	      ;;
          255) 
	        dialog --title 'Backup media' --colors --infobox "\Zb\Z1"'media Remove aborted!' 4 28 ; sleep 1
	        FN_MENU_INSTALLER
	      ;;
        esac		
	
	  if [ $(dpkg-query -W -f='${Status}' "apache2" 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
	    FN_APACHE_DEFAULT_REMOVE
	    FN_SECURE_APACHE_NO
	  fi
	
	  FN_AUTOSTART_DISABLE
	
          BACKUPDIR="$(date '+%d-%B-%Y-%H-%M')"
	  sudo mkdir -p ./Backup/removed-$BACKUPDIR
	  sudo cp ./config.txt ./Backup/removed-$BACKUPDIR
	  sudo cp /etc/motion/motion.conf ./removed-$BACKUPDIR
	  sudo cp /etc/raspimjpeg ./Backup/removed-$BACKUPDIR				
	  sudo cp $INSTALLDIR/uconfig ./Backup/removed-$BACKUPDIR
	
	  sudo rm /etc/sudoers.d/RPI_Cam_Web_Interface
	  sudo rm /usr/bin/raspimjpeg
	  sudo rm /etc/raspimjpeg
	  if [ ! "$RPICAMDIR" == "" ]; then
	    sudo rm -r $WWWROOT/$RPICAMDIR
	  else
	    # Here needed think. If RPICAMDIR not set then removed all webserver content!
	    sudo rm -r $INSTALLDIR/*
	  fi
    }
 
    FN_MEDIUM ()
    {
      package=('apache2' 'php5' 'libapache2-mod-php5' 'php5-cli' 'zip' 'nginx' 'php5-fpm' 'php5-common' 'php-apc' 'gpac motion' 'libav-tools'); 
      for i in "${package[@]}"
      do
        if [ $(dpkg-query -W -f='${Status}' "$i" 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        sudo apt-get remove -y "$i" && sudo apt-get autoremove -y
      fi
      done
    }
	
    FN_HARD ()
    {
      #Put here packages where config files also removed.
      package=('apache2' 'apache2-utils' 'nginx' 'nginx-common' 'nginx-full' 'motion' 'gpac motion'); 
	    for i in "${package[@]}"
	      do
		   if [ $(dpkg-query -W -f='${Status}' "$i" 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		    sudo apt-get remove --purge -y "$i" && sudo apt-get autoremove -y
		   fi
	    done
    }
 
    FN_UNINSTALL ()
    {
      dialog --title "Uninstall packages!"       \
      --backtitle "$backtitle"                   \
      --help-button --help-label "Hard" \
      --extra-button --extra-label Medium        \
      --ok-label Light                           \
      --cr-wrap                                  \
      --colors                                   \
      --trim                                     \
      --yesno                                    \
"\Zb\Z4Light\Zn - Removed only files.
\Zb\Z4Medium\Zn - Removed files and Uninstalled packages.
\Zb\Z1Hard\Zn - Full uninstall! \Zb\Z1(Config Files also!)\Zn" 10 68
      response=$?
      case $response in
        0) #echo "[Light] key pressed."
          FN_LIGHT
          FN_MENU_INSTALLER
        ;;
        1) #echo "[Cansel] key pressed."
          FN_MENU_INSTALLER
        ;;
        2) #echo "[Hard] key pressed."
          FN_LIGHT
          FN_HARD
	  FN_MEDIUM
        ;;
        3) #echo "[Medium] key pressed."
          FN_LIGHT
          FN_MEDIUM
        ;;
        255) #echo "[ESC] key pressed."
          FN_MENU_INSTALLER
        ;;
      esac
    }
    FN_UNINSTALL

    dialog --title 'Remove message' --infobox 'Removed everything.' 4 23 ; sleep 2
    FN_REBOOT
    ;;
  esac
done
}
FN_MENU_INSTALLER

