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

# Terminal colors
color_red="tput setaf 1"
color_green="tput setaf 2"
color_reset="tput sgr0"

cd $(dirname $(readlink -f $0))

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
        $color_green; echo "Stopped"; $color_reset
}

fn_reboot ()
{ # This is function reboot system
	$color_red; echo "You must reboot your system for the changes to take effect!"; $color_reset
	tmp_message="Do you want to reboot now?"
fn_tmp_yes ()
{
	sudo reboot
}
fn_tmp_no ()
{
	$color_red; echo "Pending system changes that require a reboot!"; $color_reset
}
fn_yesno
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
fi

source ./config.txt

fn_rpicamdir ()
{ # This is function rpicamdir in config.txt file
if ! grep -Fq "rpicamdir=" ./config.txt; then
		$color_green; echo "Where do you want to install? Please enter subfolder name or press enter for www-root."; $color_reset
		read rpicamdir
		sudo echo "# Rpicam install directory" >> ./config.txt
		sudo echo "rpicamdir=\"$rpicamdir\"" >> ./config.txt
		sudo echo "" >> ./config.txt
		$color_green; echo "\"Install directory is /var/www/$rpicamdir\""; $color_reset
else
		$color_green; echo "\"Install directory is /var/www/$rpicamdir\""; $color_reset
		tmp_message="Is that right?"
		fn_tmp_yes ()
		{
			echo ""
		}
		fn_tmp_no ()
		{
			$color_green; echo "Please enter subfolder name or press enter for www-root."; $color_reset
			read rpicamdir
			sudo sed -i "s/^rpicamdir=.*/rpicamdir=\"$rpicamdir\"/g" ./config.txt
			$color_green; echo "\"Install directory is /var/www/$rpicamdir\""; $color_reset
		}
		fn_yesno
fi
}

fn_webport ()
{ # This is function to change webserver port. Currently running only with Apache.
webport=$(cat /etc/apache2/sites-available/default | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
$color_green; echo "Currently webserver is using port \"$webport\""; $color_reset
tmp_message="Do you want to change it?"
fn_tmp_yes ()
{
	$color_green; echo "Please enter new port for webserver."; $color_reset
	read webport
	tmpfile=$(mktemp)
	sudo awk '/NameVirtualHost \*:/{c+=1}{if(c==1){sub("NameVirtualHost \*:.*","NameVirtualHost *:'$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
	sudo awk '/Listen/{c+=1}{if(c==1){sub("Listen.*","Listen '$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
	sudo awk '/<VirtualHost \*:/{c+=1}{if(c==1){sub("<VirtualHost \*:.*","<VirtualHost *:'$webport'>",$0)};print}' /etc/apache2/sites-available/default > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/sites-available/default
	if [ "$webport" != "80" ]; then
	  sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost:$webport\/cam_pic.php/g" /etc/motion/motion.conf
	else
	  sudo sed -i "s/^netcam_url\ http.*/netcam_url\ http:\/\/localhost\/cam_pic.php/g" /etc/motion/motion.conf
	fi
	sudo chown motion:www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf
	sudo service apache2 restart
	webport=$(cat /etc/apache2/sites-available/default | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
	$color_green; echo "Now webserver using port \"$webport\""; $color_reset
}
fn_tmp_no ()
{
	echo ""
}
fn_yesno
}

fn_secure ()
{ # This is function secure in config.txt file. Working only apache right now!
if [ ! -e /var/www/$rpicamdir/.htaccess ]; then
# We make missing .htacess file
sudo bash -c "cat > /var/www/$rpicamdir/.htaccess" << EOF
AuthName "RPi Cam Web Interface Restricted Area"
AuthType Basic
AuthUserFile /usr/local/.htpasswd
AuthGroupFile /dev/null
Require valid-user
EOF
sudo chown -R www-data:www-data /var/www/$rpicamdir/.htaccess
fi
if ! grep -Fq "security=" ./config.txt; then
		sudo echo "# Webserver security" >> ./config.txt
		sudo echo "security=\"no\"" >> ./config.txt
		sudo echo "user=\"\"" >> ./config.txt
		sudo echo "passwd=\"\"" >> ./config.txt
		sudo echo "" >> ./config.txt
fi

fn_sec_yes ()
{
	tmpfile=$(mktemp)
	sudo awk '/AllowOverride/{c+=1}{if(c==2){sub("AllowOverride.*","AllowOverride All",$0)};print}' /etc/apache2/sites-available/default > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/sites-available/default
	sudo awk '/; netcam_userpass/{c+=1}{if(c==1){sub("; netcam_userpass.*","netcam_userpass '$user':'$passwd'",$0)};print}' /etc/motion/motion.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/motion/motion.conf
	sudo htpasswd -b -c /usr/local/.htpasswd $user $passwd
	sudo /etc/init.d/apache2 restart
}

fn_sec_no ()
{
	tmpfile=$(mktemp)
	sudo awk '/AllowOverride/{c+=1}{if(c==2){sub("AllowOverride.*","AllowOverride None",$0)};print}' /etc/apache2/sites-available/default > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/sites-available/default
	sudo awk '/netcam_userpass/{c+=1}{if(c==1){sub("^netcam_userpass.*","; netcam_userpass value",$0)};print}' /etc/motion/motion.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/motion/motion.conf
	sudo /etc/init.d/apache2 restart
}

if [[ "$security" == "yes" && ! "$user" == "" && ! "$passwd" == "" ]] ; then
    	$color_green; echo "Security set to \""$security"\"; User set to \""$user"\"; Password set to \""$passwd"\""; $color_reset
	tmp_message="Is that correct?"
	fn_tmp_yes ()
	{
		fn_sec_yes
	}
	fn_tmp_no ()
	{
		tmp_message="Do you want to enable webserver security?"
		fn_tmp_yes ()
		{
			sudo sed -i "s/^security=.*/security=\"yes\"/g" ./config.txt
			$color_green; echo "Please enter User Name."; $color_reset
			read user
			sudo sed -i "s/^user=.*/user=\"$user\"/g" ./config.txt
			$color_green; echo "Please enter Password for $user."; $color_reset
			read passwd			
			sudo sed -i "s/^passwd=.*/passwd=\"$passwd\"/g" ./config.txt
			fn_sec_yes
		}
		fn_tmp_no ()
		{
			sudo sed -i "s/^security=.*/security=\"no\"/g" ./config.txt
			fn_sec_no
		}
		fn_yesno
		}
	fn_yesno
fi
	if [ "$security" != "yes" ] ; then	
		tmp_message="Do You want enable webserver security?"
		fn_tmp_yes ()
		{
			sudo sed -i "s/^security=.*/security=\"yes\"/g" ./config.txt
			$color_green; echo "Please enter User Name."; $color_reset
			read user
			sudo sed -i "s/^user=.*/user=\"$user\"/g" ./config.txt
			$color_green; echo "Please enter Password for $user."; $color_reset
			read passwd			
			sudo sed -i "s/^passwd=.*/passwd=\"$passwd\"/g" ./config.txt
			fn_sec_yes
		}
		fn_tmp_no ()
		{
			sudo sed -i "s/^security=.*/security=\"no\"/g" ./config.txt
			fn_sec_no
		}
		fn_yesno
	fi
}

# Autostart. We edit rc.local
fn_autostart_disable ()
{
  tmpfile=$(mktemp)
  sudo sed '/#START/,/#END/d' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
  # Remove to growing plank lines.
  sudo awk '!NF {if (++n <= 1) print; next}; {n=0;print}' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
  sudo chmod 755 /etc/rc.local
  sudo sed -i "s/^autostart.*/autostart=\"no\"/g" ./config.txt
}

fn_autostart ()
{
if ! grep -Fq "autostart=" ./config.txt; then
  sudo echo "# Enable or disable autostart" >> ./config.txt
  sudo echo "autostart=\"\"" >> ./config.txt
  sudo echo "" >> ./config.txt
fi

fn_autostart_enable ()
{
if ! grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
  sudo sed -i '/exit 0/d' /etc/rc.local
sudo bash -c "cat > /etc/rc.local" << EOF
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
}

if [ "$autostart" != "yes" ] ; then
  $color_red; echo "Auto Start is currently disabled!"; $color_reset
  tmp_message="Do You want enable Auto Start in boot time?"
  fn_tmp_yes ()
    {
	  fn_autostart_enable
	}
	  fn_tmp_no ()
	{
	  fn_autostart_disable
	}
  fn_yesno
else
  $color_green; echo "Auto Start is currently enabled!"; $color_reset
  tmp_message="Do You want disable Auto Start in boot time?"
	fn_tmp_yes ()
	{
	  fn_autostart_disable
	}
	  fn_tmp_no ()
	{
	  fn_autostart_enable
	}
	fn_yesno		
fi
}

# We edit /etc/apache2/sites-available/default
fn_apache_default_install ()
{
if ! grep -Fq 'cam_pic.php' /etc/apache2/sites-available/default; then
  if [ ! "$rpicamdir" == "" ]; then
    sudo sed -i "s/DocumentRoot\ \/var\/www.*/DocumentRoot\ \/var\/www\/$rpicamdir/g" /etc/apache2/sites-available/default
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

case "$1" in

  remove)
        sudo killall raspimjpeg
        tmp_message="Do You want uninstall webserver and php packages also?"
	fn_tmp_yes ()
	{
          package=('apache2' 'php5' 'libapache2-mod-php5' 'zip' 'nginx' 'php5-fpm' 'php5-common' 'php-apc' 'gpac motion'); 
          for i in "${package[@]}"
           do
             if [ $(dpkg-query -W -f='${Status}' "$i" 2>/dev/null | grep -c "ok installed") -eq 1 ];
             then
               sudo apt-get remove -y "$i"
             fi
           done
          sudo apt-get autoremove -y
	}
	fn_tmp_no ()
	{
		echo ""
	}
	fn_yesno

        fn_rpicamdir
	if [ ! "$rpicamdir" == "" ]; then
	  sudo rm -r /var/www/$rpicamdir
	else
	  # Here needed think. If rpicamdir not set then removed all webserver content!
	  sudo rm -r /var/www/*
	fi
        sudo rm /etc/sudoers.d/RPI_Cam_Web_Interface
        sudo rm /usr/bin/raspimjpeg
        sudo rm /etc/raspimjpeg
        fn_autostart_disable
        fn_apache_default_remove

        $color_green; echo "Removed everything"; $color_reset
        fn_reboot
        ;;

  autostart)
	fn_autostart
	
        $color_green; echo "Changed autostart"; $color_reset
        ;;

  install)
        sudo killall raspimjpeg
        sudo apt-get install -y apache2 php5 libapache2-mod-php5 gpac motion zip

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
        fi
        sudo cp -r etc/motion/motion.conf /etc/motion/
        sudo usermod -a -G video www-data
        if [ -e /var/www/$rpicamdir/uconfig ]; then
          sudo chown www-data:www-data /var/www/$rpicamdir/uconfig
        fi
        
        if [ ! "$rpicamdir" == "" ]; then
          sudo sed -i "s/www\//www\/$rpicamdir\//g" /var/www/$rpicamdir/schedule.php
        fi
        fn_webport
        fn_secure
	sudo chown motion:www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf

        $color_green; echo "Installer finished"; $color_reset
        fn_reboot
        ;;

  install_nginx)
        sudo killall raspimjpeg
        sudo apt-get install -y nginx php5-fpm php5-common php-apc

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
        fi
        sudo cp -r etc/motion/motion.conf /etc/motion/
        if [ ! "$rpicamdir" == "" ]; then
         sudo sed -i "s/^netcam_url.*/netcam_url http:\/\/localhost\/$rpicamdir\/cam_pic.php/g" /etc/motion/motion.conf
        fi
        sudo usermod -a -G video www-data
        if [ -e /var/www/$rpicamdir/uconfig ]; then
          sudo chown www-data:www-data /var/www/$rpicamdir/uconfig
        fi
        
        if [ ! "$rpicamdir" == "" ]; then
          sudo sed -i "s/www\//www\/$rpicamdir\//g" /var/www/$rpicamdir/schedule.php
        fi
	sudo chown motion:www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf

        $color_green; echo "Installer finished"; $color_reset
        fn_reboot
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
            $color_green; echo "Commits match."; $color_reset
        else
            $color_red; echo "Commits don't match. We update."; $color_reset
            git pull origin master
        fi
        trap : 0

        $color_green; echo "Update finished"; $color_reset
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
        fn_webport
        fn_secure

        $color_green; echo "Upgrade finished"; $color_reset
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
        
        $color_green; echo "Started"; $color_reset
        ;;

  debug)
        fn_stop
        sudo mkdir -p /dev/shm/mjpeg
        sudo chown www-data:www-data /dev/shm/mjpeg
        sudo chmod 777 /dev/shm/mjpeg
        sleep 1;sudo su -c 'raspimjpeg &' www-data
        sleep 1;sudo sudo su -c "php /var/www/$rpicamdir/schedule.php &" www-data
        
        $color_green; echo "Started with debug"; $color_reset
        ;;

  stop)
        fn_stop
        ;;

  *)
        $color_red; echo "No or invalid option selected"
        echo "Usage: ./RPi_Cam_Web_Interface_Installer.sh {install|install_nginx|update|upgrade|remove|start|stop|autostart|debug}"; $color_reset
        ;;

esac

