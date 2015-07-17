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
# The folder name must be a subfolder of /var/www/ which will be created
#  accordingly, and must not include leading nor trailing / character.
# Default upstream behaviour: rpicamdir="" (installs in /var/www/)

if [ $(dpkg-query -W -f='${Status}' "dialog" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  sudo apt-get install -y dialog
fi

# Terminal colors
color_red="tput setaf 1"
color_green="tput setaf 2"
color_reset="tput sgr0"

cd $(dirname $(readlink -f $0))

# We enable debug installer script
if ! grep -Fq "debug=" ./config.txt; then
  sudo echo "# Enable or disable debug for installer script" >> ./config.txt
  sudo echo "debug=\"no\"" >> ./config.txt
  sudo echo "" >> ./config.txt
  sudo chmod 664 ./config.txt
fi

fn_yesno ()
{ # This is function yes or no
        $color_green; read -p "$tmp_message <y/n> " prompt; $color_reset
		
		if [[ $prompt =~ [yY](es)* ]]; then
#			$color_green; echo "Your answer was YES"; $color_reset
			fn_tmp_yes
		elif [[ $prompt =~ [nN](o)* ]]; then
#			$color_green; echo "Your answer was NO"; $color_reset
			fn_tmp_no
		else
			$color_red; echo "Please type Y or N!"; $color_reset
			fn_yesno
		fi
}
: '
tmp_message="Are you sure you want to continue?"
fn_tmp_yes ()
{
	echo "YES script"
}
fn_tmp_no ()
{
	echo "NO script"
}
fn_yesno
'
	
fn_stop ()
{ # This is function stop
        sudo killall raspimjpeg
        sudo killall php
        sudo killall motion
        dialog --title 'Stop message' --infobox 'Stopped.' 4 16 ; sleep 2
}

fn_reboot ()
{ # This is function reboot system
  dialog --title "You must reboot your system!" --backtitle "$backtitle" --yesno "Do you want to reboot now?" 5 33
  response=$?
    case $response in
      0) sudo reboot;;
      1) dialog --title 'Reboot message' --infobox 'Pending system changes that require a reboot!' 4 28 ; sleep 2;;
      255) dialog --title 'Reboot message' --infobox 'Pending system changes that require a reboot!' 4 28 ; sleep 2;;
    esac
}

fn_abort()
{
    $color_red; echo >&2 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred. Exiting..." >&2; $color_reset
    exit 1
}

# Config options located in ./config.txt. In first run script makes that file for you.
if [ ! -e ./config.txt ]; then
      sudo echo "#This is config file for main installer. Put any extra options in here." > ./config.txt
      sudo echo "" >> ./config.txt
      sudo chmod 664 ./config.txt
fi

source ./config.txt

fn_rpicamdir ()
{ # This is function rpicamdir in config.txt file
  if ! grep -Fq "rpicamdir=" ./config.txt; then
    sudo echo "# Rpicam install directory" >> ./config.txt
    sudo echo "rpicamdir=\"\"" >> ./config.txt
    sudo echo "" >> ./config.txt
  fi

  source ./config.txt
  
  tmpfile=$(mktemp)
  dialog  --backtitle "$backtitle" --title "Default www-root is /var/www" --cr-wrap --inputbox "\
  Current install path is /var/www/$rpicamdir
  Enter new install Subfolder if you like." 8 52 $rpicamdir 2>$tmpfile
			
  sel=$?
			
  rpicamdir=`cat $tmpfile`
  case $sel in
  0)
    sudo sed -i "s/^rpicamdir=.*/rpicamdir=\"$rpicamdir\"/g" ./config.txt	
  ;;
  1) source ./config.txt ;;
  255) source ./config.txt ;;
  esac

  dialog --title 'Install path' --infobox "Install path is set /var/www/$rpicamdir" 4 48 ; sleep 3
  sudo chmod 664 ./config.txt

  if [ "$debug" == "yes" ]; then
    dialog --title "fn_rpicamdir ./config.txt contains" --textbox ./config.txt 22 70
  fi
}

fn_apacheport ()
{		
  if ! grep -Fq "webport=" ./config.txt; then
    webport=$(cat /etc/apache2/sites-available/default | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
    sudo echo "# Apache web server port" >> ./config.txt
    sudo echo "webport=\"$webport\"" >> ./config.txt
    sudo echo "" >> ./config.txt
  fi
		
  source ./config.txt
		
  if [ "$webport" == "" ]; then
    webport=$(cat /etc/apache2/sites-available/default | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
    sudo sed -i "s/^webport=.*/webport=\"$webport\"/g" ./config.txt
  fi		
		
  tmpfile=$(mktemp)
  dialog  --backtitle "$backtitle" --title "Current Apache web server port is $webport" --inputbox "Enter new port:" 8 40 $webport 2>$tmpfile
			
  sel=$?
			
  webport=`cat $tmpfile`
  case $sel in
  0)
    sudo sed -i "s/^webport=.*/webport=\"$webport\"/g" ./config.txt	
  ;;
  1) source ./config.txt ;;
  255) source ./config.txt ;;
  esac
			
  tmpfile=$(mktemp)
  sudo awk '/NameVirtualHost \*:/{c+=1}{if(c==1){sub("NameVirtualHost \*:.*","NameVirtualHost *:'$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
  sudo awk '/Listen/{c+=1}{if(c==1){sub("Listen.*","Listen '$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
  sudo awk '/<VirtualHost \*:/{c+=1}{if(c==1){sub("<VirtualHost \*:.*","<VirtualHost *:'$webport'>",$0)};print}' /etc/apache2/sites-available/default > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/sites-available/default
  if [ ! "$rpicamdir" == "" ]; then
    if [ "$webport" != "80" ]; then
      sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost:$webport\/$rpicamdir\/cam_pic.php/g" /etc/motion/motion.conf
    else
      sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost\/$rpicamdir\/cam_pic.php/g" /etc/motion/motion.conf
    fi
  else
    if [ "$webport" != "80" ]; then
      sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost:$webport\/cam_pic.php/g" /etc/motion/motion.conf
    else
      sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost\/cam_pic.php/g" /etc/motion/motion.conf
    fi
  fi
  sudo chown motion:www-data /etc/motion/motion.conf
  sudo chmod 664 /etc/motion/motion.conf
  sudo service apache2 restart
}

fn_secure_apache_no ()
{
	if [ "$debug" == "yes" ]; then
	  dialog --title 'fn_secure_apache_no' --infobox 'fn_secure_apache_no STARTED.' 4 25 ; sleep 2
	fi
	tmpfile=$(mktemp)
	sudo awk '/AllowOverride/{c+=1}{if(c==2){sub("AllowOverride.*","AllowOverride None",$0)};print}' /etc/apache2/sites-available/default > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/sites-available/default
	sudo awk '/netcam_userpass/{c+=1}{if(c==1){sub("^netcam_userpass.*","; netcam_userpass value",$0)};print}' /etc/motion/motion.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/motion/motion.conf
	sudo /etc/init.d/apache2 restart
}

fn_secure_apache ()
{ # This is function secure in config.txt file. Working only apache right now! GUI mode.
if ! grep -Fq "security=" ./config.txt; then
		sudo echo "# Webserver security" >> ./config.txt
		sudo echo "security=\"no\"" >> ./config.txt
		sudo echo "user=\"\"" >> ./config.txt
		sudo echo "passwd=\"\"" >> ./config.txt
		sudo echo "" >> ./config.txt
		sudo chmod 664 ./config.txt
fi

source ./config.txt

fn_secure_apache_yes ()
{
	if [ "$debug" == "yes" ]; then
	  dialog --title 'fn_secure_apache_yes' --infobox 'fn_secure_apache_yes STARTED.' 4 25 ; sleep 2
	fi
	tmpfile=$(mktemp)
	sudo awk '/AllowOverride/{c+=1}{if(c==2){sub("AllowOverride.*","AllowOverride All",$0)};print}' /etc/apache2/sites-available/default > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/sites-available/default
	sudo awk '/; netcam_userpass/{c+=1}{if(c==1){sub("; netcam_userpass.*","netcam_userpass '$user':'$passwd'",$0)};print}' /etc/motion/motion.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/motion/motion.conf
	sudo htpasswd -b -c /usr/local/.htpasswd $user $passwd
	sudo /etc/init.d/apache2 restart
}

# We make missing .htacess file
if [ ! -e /var/www/$rpicamdir/.htaccess ]; then
sudo bash -c "cat > /var/www/$rpicamdir/.htaccess" << EOF
AuthName "RPi Cam Web Interface Restricted Area"
AuthType Basic
AuthUserFile /usr/local/.htpasswd
AuthGroupFile /dev/null
Require valid-user
EOF
sudo chown -R www-data:www-data /var/www/$rpicamdir/.htaccess
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
  fn_secure_apache_no
  sudo sed -i "s/^security=.*/security=\"no\"/g" ./config.txt
else
  fn_secure_apache_yes
fi

sudo chown motion:www-data /etc/motion/motion.conf
sudo chmod 664 /etc/motion/motion.conf
sudo chmod 664 ./config.txt
sudo service apache2 restart

if [ "$debug" == "yes" ]; then
  dialog --title "fn_secure_apache /etc/apache2/sites-available/default contains" --textbox /etc/apache2/sites-available/default 22 70
  dialog --title "fn_secure_apache /etc/motion/motion.conf contains" --textbox /etc/motion/motion.conf 22 70
  dialog --title "fn_secure_apache ./config.txt contains" --textbox ./config.txt 22 70
fi
}

# Autostart. We edit rc.local
fn_autostart_disable ()
{
  tmpfile=$(mktemp)
  sudo sed '/#START/,/#END/d' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
  # Remove to growing plank lines.
  sudo awk '!NF {if (++n <= 1) print; next}; {n=0;print}' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
  sudo sed -i "s/^autostart.*/autostart=\"no\"/g" ./config.txt
			  
  # Finally we set owners and permissions all files what we changed.
  sudo chown root:root /etc/rc.local
  sudo chmod 755 /etc/rc.local
  sudo chmod 664 ./config.txt
			  
  if [ "$debug" == "yes" ]; then
    dialog --title "fn_autostart_disable /etc/rc.local contains" --textbox /etc/rc.local 22 70
    dialog --title "fn_autostart_disable ./config.txt contains" --textbox ./config.txt 22 70
  fi
}

fn_autostart ()
{
  if ! grep -Fq "autostart=" ./config.txt; then
    sudo echo "# Enable or disable autostart" >> ./config.txt
    sudo echo "autostart=\"\"" >> ./config.txt
    sudo echo "" >> ./config.txt
    sudo chmod 664 ./config.txt
  fi
		
fn_autostart_enable ()
{
if ! grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
  sudo sed -i '/exit 0/d' /etc/rc.local
sudo bash -c "cat >> /etc/rc.local" << EOF
#START RASPIMJPEG SECTION
mkdir -p /dev/shm/mjpeg
chown www-data:www-data /dev/shm/mjpeg
chmod 777 /dev/shm/mjpeg
sleep 4;su -c 'raspimjpeg > /dev/null 2>&1 &' www-data
if [ -e /etc/debian_version ]; then
  sleep 4;su -c "php /var/www/schedule.php > /dev/null 2>&1 &" www-data
else
  sleep 4;su -s '/bin/bash' -c "php /var/www/schedule.php > /dev/null 2>&1 &" www-data
fi
#END RASPIMJPEG SECTION

exit 0
EOF
  sudo chmod 755 /etc/rc.local
fi

if [ ! "$rpicamdir" == "" ]; then
  sudo sed -i "s/\/var\/www\/schedule.php/\/var\/www\/$rpicamdir\/schedule.php/" /etc/rc.local
else
  sudo sed -i "s/\/var\/www\/.*.\/schedule.php/\/var\/www\/schedule.php/" /etc/rc.local
fi

sudo sed -i "s/^autostart.*/autostart=\"yes\"/g" ./config.txt
			  
# Finally we set owners and permissions all files what we changed.
sudo chown root:root /etc/rc.local
sudo chmod 755 /etc/rc.local
sudo chmod 664 ./config.txt
			  
if [ "$debug" == "yes" ]; then
  dialog --title "fn_autostart_enable /etc/rc.local contains" --textbox /etc/rc.local 22 70
  dialog --title "fn_autostart_enable ./config.txt contains" --textbox ./config.txt 22 70
fi
}
		
source ./config.txt
		
if [ "$autostart" == "" ]; then
  if grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
    sudo sed -i "s/^autostart.*/autostart=\"yes\"/g" ./config.txt
  else
    sudo sed -i "s/^autostart.*/autostart=\"no\"/g" ./config.txt
  fi
fi
			
if grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
  status="Enabled"
else
  status="Disabled"
fi
		
# We look is autostart manually set.
if [[ "$autostart" == "yes" && "$status" == "Disabled" ]] ; then
  fn_autostart_enable
elif [[ "$autostart" == "no" && "$status" == "Enabled" ]] ; then
  fn_autostart_disable
else
  dialog --title "Curently auto start in boot time is $status" --backtitle "$backtitle" --yesno "Do you want enable auto start in boot time?" 7 60
  response=$?
    case $response in
      0) fn_autostart_enable;;
      1) fn_autostart_disable;;
      255) echo "[ESC] key pressed.";;
esac
fi
		
if grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
  dialog --title 'Autostart message' --infobox 'Autostart Enabled.' 4 23 ; sleep 2
else
  dialog --title 'Autostart message' --infobox 'Autostart Disabled.' 4 23 ; sleep 2
fi
			
# Finally we set owners and permissions all files what we changed.
sudo chown root:root /etc/rc.local
sudo chmod 755 /etc/rc.local
sudo chmod 664 ./config.txt
			
if [ "$debug" == "yes" ]; then
  dialog --title "fn_autostart /etc/rc.local contains" --textbox /etc/rc.local 22 70
  dialog --title "fn_autostart ./config.txt contains" --textbox ./config.txt 22 70
fi
}

# We edit /etc/apache2/sites-available/default
fn_apache_default_install ()
{
if ! grep -Fq 'cam_pic.php' /etc/apache2/sites-available/default; then
  if [ ! "$rpicamdir" == "" ]; then
    sudo sed -i "s/<Directory\ \/var\/www\/.*/<Directory\ \/var\/www\/$rpicamdir\/>/g" /etc/apache2/sites-available/default
  fi	
  sudo sed -i '/CustomLog\ ${APACHE_LOG_DIR}\/access.log\ combined/i \	SetEnvIf\ Request_URI\ "\/cam_pic.php$|\/status_mjpeg.php$"\ dontlog' /etc/apache2/sites-available/default
  sudo sed -i 's/CustomLog\ ${APACHE_LOG_DIR}\/access.log.*/CustomLog\ ${APACHE_LOG_DIR}\/access.log\ common\ env=!dontlog/g' /etc/apache2/sites-available/default
fi
}
fn_apache_default_remove ()
{
if grep -Fq 'cam_pic.php' /etc/apache2/sites-available/default; then
  if [ ! "$rpicamdir" == "" ]; then
    sudo sed -i 's/DocumentRoot\ \/var\/www.*/DocumentRoot\ \/var\/www/g' /etc/apache2/sites-available/default
    sudo sed -i "s/<Directory\ \/var\/www\/$rpicamdir\/>/<Directory\ \/var\/www\/>/g" /etc/apache2/sites-available/default
  fi
  sudo sed -i '/SetEnvIf\ Request_URI\ "\/cam_pic.php$|\/status_mjpeg.php$"\ dontlog/d' /etc/apache2/sites-available/default
  sudo sed -i 's/CustomLog\ ${APACHE_LOG_DIR}\/access.log\ common\ env=!dontlog/CustomLog\ ${APACHE_LOG_DIR}\/access.log\ combined/g' /etc/apache2/sites-available/default
fi
}

# Start and Stop without GUI mode.
case "$1" in
  start)
        fn_stop
        sudo mkdir -p /dev/shm/mjpeg
        sudo chown www-data:www-data /dev/shm/mjpeg
        sudo chmod 777 /dev/shm/mjpeg
        sleep 1;sudo su -c 'raspimjpeg > /dev/null &' www-data
        if [ -e /etc/debian_version ]; then
          sleep 1;sudo su -c "php /var/www/$rpicamdir/schedule.php > /dev/null &" www-data
        else
          sleep 1;sudo su -c '/bin/bash' -c "php /var/www/$rpicamdir/schedule.php > /dev/null &" www-data
        fi

        dialog --title 'Start message' --infobox 'Started.' 4 16 ; sleep 2
	exit
        ;;

  stop)
        fn_stop
	exit
        ;;  
esac

fn_menu_installer ()
{
# We using only "raspimjpeg" right now, but we need extracted values also for future development.
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
	
versionfile="./www/config.php"
version=$(cat $versionfile | grep "'APP_VERSION'" | cut -d "'" -f4)
backtitle="Copyright (c) 2014, Silvan Melchior. RPi Cam $version"

cmd=(dialog --backtitle "$backtitle" --title "RPi Cam Web Interface Installer" --menu "Select your option:" 16 76 16)

options=("1 install" "Install (Apache web server based)"
         "2 install_nginx" "Install (Nginx web server based)"
         "3 start" "Start RPi Cam \Zb\Z1$stopped_rpicam"
         "4 stop" "Stop RPi Cam \Zb\Z2$started_rpicam"
         "5 autostart" "Autostart ON/OFF RPi Cam"
         "6 update" "Update RPi Cam installer"
         "7 upgrade" "Upgrade RPi Cam"
         "8 debug" "Run RPi Cam with debug mode"
         "9 remove" "Remove RPi Cam")

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
  case $choice in

  install)
        sudo killall raspimjpeg
        sudo apt-get install -y apache2 php5 php5-cli libapache2-mod-php5 gpac motion zip

        fn_rpicamdir
        sudo mkdir -p /var/www/$rpicamdir/media
        sudo cp -r www/* /var/www/$rpicamdir/
        if [ -e /var/www/$rpicamdir/index.html ]; then
          sudo rm /var/www/$rpicamdir/index.html
        fi
        sudo chown -R www-data:www-data /var/www/$rpicamdir
        
        if [ ! -e /var/www/$rpicamdir/FIFO ]; then
          sudo mknod /var/www/$rpicamdir/FIFO p
        fi
        sudo chmod 666 /var/www/$rpicamdir/FIFO
        
        if [ ! -e /var/www/$rpicamdir/FIFO1 ]; then
          sudo mknod /var/www/$rpicamdir/FIFO1 p
        fi
        sudo chmod 666 /var/www/$rpicamdir/FIFO1
        sudo chmod 755 /var/www/$rpicamdir/raspizip.sh

        if [ ! -e /var/www/$rpicamdir/cam.jpg ]; then
          sudo ln -sf /run/shm/mjpeg/cam.jpg /var/www/$rpicamdir/cam.jpg
        fi

	fn_apache_default_install
        sudo cp etc/apache2/conf.d/other-vhosts-access-log /etc/apache2/conf.d/other-vhosts-access-log
        sudo chmod 644 /etc/apache2/conf.d/other-vhosts-access-log

        sudo cp etc/sudoers.d/RPI_Cam_Web_Interface /etc/sudoers.d/
        sudo chmod 440 /etc/sudoers.d/RPI_Cam_Web_Interface

        sudo cp -r bin/raspimjpeg /opt/vc/bin/
        sudo chmod 755 /opt/vc/bin/raspimjpeg
        if [ ! -e /usr/bin/raspimjpeg ]; then
          sudo ln -s /opt/vc/bin/raspimjpeg /usr/bin/raspimjpeg
        fi

        if [ "$rpicamdir" == "" ]; then
          cat etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
        else
          sed -e "s/www/www\/$rpicamdir/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
        fi
        if [ `cat /proc/cmdline |awk -v RS=' ' -F= '/boardrev/ { print $2 }'` == "0x11" ]; then
          sed -i "s/^camera_num 0/camera_num 1/g" etc/raspimjpeg/raspimjpeg
        fi
        if [ -e /etc/raspimjpeg ]; then
          $color_green; echo "Your custom raspimjpg backed up at /etc/raspimjpeg.bak"; $color_reset
          sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
        fi
        sudo cp -r etc/raspimjpeg/raspimjpeg /etc/
        sudo chmod 644 /etc/raspimjpeg
        if [ ! -e /var/www/$rpicamdir/raspimjpeg ]; then
          sudo ln -s /etc/raspimjpeg /var/www/$rpicamdir/raspimjpeg
        fi

	fn_autostart

        if [ "$rpicamdir" == "" ]; then
          cat etc/motion/motion.conf.1 > etc/motion/motion.conf
        else
          sed -e "s/www/www\/$rpicamdir/" etc/motion/motion.conf.1 > etc/motion/motion.conf
          sed -i "s/^netcam_url.*/netcam_url http:\/\/localhost\/$rpicamdir\/cam_pic.php/g" etc/motion/motion.conf		
        fi
        sudo cp -r etc/motion/motion.conf /etc/motion/
        sudo usermod -a -G video www-data
        if [ -e /var/www/$rpicamdir/uconfig ]; then
          sudo chown www-data:www-data /var/www/$rpicamdir/uconfig
        fi
        
        if [ ! "$rpicamdir" == "" ]; then
          sudo sed -i "s/www\//www\/$rpicamdir\//g" /var/www/$rpicamdir/schedule.php
        fi
        fn_apacheport
        fn_secure_apache
	sudo chown motion:www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf

        dialog --title 'Install message' --infobox 'Installer finished.' 4 25 ; sleep 2
        fn_reboot
        ;;

  install_nginx)
        sudo killall raspimjpeg
        sudo apt-get install -y nginx php5-fpm php5-cli php5-common php-apc gpac motion zip

        fn_rpicamdir
        sudo mkdir -p /var/www/$rpicamdir/media
        sudo cp -r www/* /var/www/$rpicamdir/
        if [ -e /var/www/$rpicamdir/index.html ]; then
          sudo rm /var/www/$rpicamdir/index.html
        fi
        sudo chown -R www-data:www-data /var/www/$rpicamdir

        if [ ! -e /var/www/$rpicamdir/FIFO ]; then
          sudo mknod /var/www/$rpicamdir/FIFO p
        fi
        sudo chmod 666 /var/www/$rpicamdir/FIFO

        if [ ! -e /var/www/$rpicamdir/FIFO1 ]; then
          sudo mknod /var/www/$rpicamdir/FIFO1 p
        fi
        sudo chmod 666 /var/www/$rpicamdir/FIFO1
        sudo chmod 755 /var/www/$rpicamdir/raspizip.sh

        if [ ! -e /var/www/$rpicamdir/cam.jpg ]; then
          sudo ln -sf /run/shm/mjpeg/cam.jpg /var/www/$rpicamdir/cam.jpg
        fi

        if [ "$rpicamdir" == "" ]; then
          sudo cat etc/nginx/sites-available/rpicam.1 > etc/nginx/sites-available/rpicam
        else
          sudo sed -e "s:root /var/www;:root /var/www/$rpicamdir;:g" etc/nginx/sites-available/rpicam.1 > etc/nginx/sites-available/rpicam
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

        if [ "$rpicamdir" == "" ]; then
          sudo cat etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
        else
          sudo sed -e "s/www/www\/$rpicamdir/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
        fi
        if [ `cat /proc/cmdline |awk -v RS=' ' -F= '/boardrev/ { print $2 }'` == "0x11" ]; then
          sed -i "s/^camera_num 0/camera_num 1/g" etc/raspimjpeg/raspimjpeg
        fi
        if [ -e /etc/raspimjpeg ]; then
          $color_green; echo "Your custom raspimjpg backed up at /etc/raspimjpeg.bak"; $color_reset
          sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
        fi
        sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
        sudo cp -r etc/raspimjpeg/raspimjpeg /etc/
        sudo chmod 644 /etc/raspimjpeg
        if [ ! -e /var/www/$rpicamdir/raspimjpeg ]; then
          sudo ln -s /etc/raspimjpeg /var/www/$rpicamdir/raspimjpeg
        fi

	fn_autostart

        if [ "$rpicamdir" == "" ]; then
          sudo cat etc/motion/motion.conf.1 > etc/motion/motion.conf
        else
          sudo sed -e "s/www/www\/$rpicamdir/" etc/motion/motion.conf.1 > etc/motion/motion.conf
          sudo sed -i "s/^netcam_url.*/netcam_url http:\/\/localhost\/$rpicamdir\/cam_pic.php/g" etc/motion/motion.conf
        fi
        sudo cp -r etc/motion/motion.conf /etc/motion/
        sudo usermod -a -G video www-data
        if [ -e /var/www/$rpicamdir/uconfig ]; then
          sudo chown www-data:www-data /var/www/$rpicamdir/uconfig
        fi
        
        if [ ! "$rpicamdir" == "" ]; then
          sudo sed -i "s/www\//www\/$rpicamdir\//g" /var/www/$rpicamdir/schedule.php
        fi
	sudo chown motion:www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf

        dialog --title 'Install message' --infobox 'Installer finished.' 4 25 ; sleep 2
        fn_reboot
        ;;

  start)
        fn_stop
        sudo mkdir -p /dev/shm/mjpeg
        sudo chown www-data:www-data /dev/shm/mjpeg
        sudo chmod 777 /dev/shm/mjpeg
        sleep 1;sudo su -c 'raspimjpeg > /dev/null &' www-data
        if [ -e /etc/debian_version ]; then
          sleep 1;sudo su -c "php /var/www/$rpicamdir/schedule.php > /dev/null &" www-data
        else
          sleep 1;sudo su -c '/bin/bash' -c "php /var/www/$rpicamdir/schedule.php > /dev/null &" www-data
        fi
        
        dialog --title 'Start message' --infobox 'Started.' 4 16 ; sleep 2
        fn_menu_installer
        ;;
        
  stop)
        fn_stop
        fn_menu_installer
        ;;
        
  autostart)
	fn_autostart
	
        dialog --title 'Autostart message' --infobox 'Changed autostart.' 4 23 ; sleep 2
        ;;
        
  update)
        trap 'fn_abort' 0
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
        fn_menu_installer
        ;;

  upgrade)
        sudo killall raspimjpeg
        sudo apt-get install -y zip

        fn_rpicamdir
        sudo cp -r bin/raspimjpeg /opt/vc/bin/
        sudo chmod 755 /opt/vc/bin/raspimjpeg
        sudo cp -r www/* /var/www/$rpicamdir/

        if [ ! -e /var/www/$rpicamdir/raspimjpeg ]; then
          sudo ln -s /etc/raspimjpeg /var/www/$rpicamdir/raspimjpeg
        fi
        sudo chmod 755 /var/www/$rpicamdir/raspizip.sh
        fn_apacheport
        fn_secure_apache

        dialog --title 'Upgrade message' --infobox 'Upgrade finished.' 4 20 ; sleep 2
        ;;

  debug)
        fn_stop
        sudo mkdir -p /dev/shm/mjpeg
        sudo chown www-data:www-data /dev/shm/mjpeg
        sudo chmod 777 /dev/shm/mjpeg
        sleep 1;sudo su -c 'raspimjpeg &' www-data
        if [ -e /etc/debian_version ]; then
          sleep 1;sudo sudo su -c "php /var/www/$rpicamdir/schedule.php &" www-data
        else
          sleep 1;sudo su -c '/bin/bash' -c "php /var/www/$rpicamdir/schedule.php &" www-data
        fi        
        
        $color_red; echo "Started with debug"; $color_reset
        ;;

  remove)
	sudo killall raspimjpeg
        
	dialog --title "Uninstall packages!" --backtitle "$backtitle" --yesno "Do You want uninstall webserver and php packages also?" 6 35
	response=$?
	  case $response in
	    0) 
	      package=('apache2' 'php5' 'libapache2-mod-php5' 'php5-cli' 'zip' 'nginx' 'php5-fpm' 'php5-common' 'php-apc' 'gpac motion'); 
	      for i in "${package[@]}"
	      do
		if [ $(dpkg-query -W -f='${Status}' "$i" 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		  sudo apt-get remove -y "$i"
		fi
	      done
	    sudo apt-get autoremove -y	  
	    ;;
	    1) dialog --title 'Uninstall message' --infobox 'Webserver and php packages not uninstalled.' 4 33 ; sleep 2;;
	    255) dialog --title 'Uninstall message' --infobox 'Webserver and php packages not uninstalled.' 4 33 ; sleep 2;;
	  esac
	
	sudo mkdir ./Backup
	
	if [ ! "$rpicamdir" == "" ]; then
	  sudo cp /var/www/$rpicamdir/uconfig ./Backup
	  sudo rm -r /var/www/$rpicamdir
	else
	  # Here needed think. If rpicamdir not set then removed all webserver content!
	  sudo cp /var/www/uconfig ./Backup
	  sudo rm -r /var/www/*
	fi
	sudo cp /etc/motion/motion.conf ./Backup
	sudo cp /etc/raspimjpeg ./Backup
	sudo rm /etc/sudoers.d/RPI_Cam_Web_Interface
	sudo rm /usr/bin/raspimjpeg
	sudo rm /etc/raspimjpeg
	fn_autostart_disable
        
	if [ $(dpkg-query -W -f='${Status}' "apache2" 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
	  fn_apache_default_remove
	  fn_secure_apache_no
	fi

        dialog --title 'Remove message' --infobox 'Removed everything.' 4 23 ; sleep 2
        fn_reboot
        ;;

  esac
done
}
fn_menu_installer
