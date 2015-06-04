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
{ # This is function webport in config.txt file. Currently running only with Apache.
webport=$(cat ./default | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
$color_green; echo "Currently webserver running in port \"$webport\""; $color_reset
tmp_message="Do you want to change it?"
fn_tmp_yes ()
{
	$color_green; echo "Please enter what port do you want webserver is running."; $color_reset
	read webport
	tmpfile=$(mktemp)
	awk '/NameVirtualHost \*:/{c+=1}{if(c==1){sub("NameVirtualHost \*:.*","NameVirtualHost *:'$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && mv "$tmpfile" /etc/apache2/ports.conf
	awk '/Listen/{c+=1}{if(c==1){sub("Listen.*","Listen '$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && mv "$tmpfile" /etc/apache2/ports.conf
	awk '/<VirtualHost \*:/{c+=1}{if(c==1){sub("<VirtualHost \*:.*","<VirtualHost *:'$webport'>",$0)};print}' /etc/apache2/sites-available/default > "$tmpfile" && mv "$tmpfile" /etc/apache2/sites-available/default
	sudo service apache2 restart
	webport=$(cat ./default | grep "<VirtualHost" | cut -d ":" -f2 | cut -d ">" -f1)
	$color_green; echo "Now webserver running in port \"$webport\""; $color_reset
}
fn_tmp_no ()
{
	echo ""
}
fn_yesno
}

case "$1" in

  remove)
        sudo killall raspimjpeg
        sudo apt-get remove -y apache2 php5 libapache2-mod-php5 gpac motion zip
        sudo apt-get autoremove -y

	fn_rpicamdir
        sudo rm -r /var/www/$rpicamdir/*
        sudo rm /etc/sudoers.d/RPI_Cam_Web_Interface
        sudo rm /usr/bin/raspimjpeg
        sudo rm /etc/raspimjpeg
        sudo cp -r /etc/rc.local.bak /etc/rc.local
        sudo chmod 755 /etc/rc.local

        $color_green; echo "Removed everything"; $color_reset
        ;;

  remove_nginx)
        sudo killall raspimjpeg
        sudo apt-get remove -y nginx php5 php5-fpm php5-common php-apc gpac motion
        sudo apt-get autoremove -y

	fn_rpicamdir
        sudo rm -r /var/www/$rpicamdir/*
        sudo rm /etc/sudoers.d/RPI_Cam_Web_Interface
        sudo rm /usr/bin/raspimjpeg
        sudo rm /etc/raspimjpeg
        sudo cp -r /etc/rc.local.bak /etc/rc.local
        sudo chmod 755 /etc/rc.local

        $color_green; echo "Removed everything"; $color_reset
        ;;

  autostart_yes)
        sudo cp -r etc/rc_local_run/rc.local /etc/
        sudo chmod 755 /etc/rc.local
        $color_green; echo "Changed autostart"; $color_reset
        ;;

  autostart_no)
        sudo cp -r /etc/rc.local.bak /etc/rc.local
        sudo chmod 755 /etc/rc.local
        $color_green; echo "Changed autostart"; $color_reset
        ;;

  install)
        sudo killall raspimjpeg
        sudo apt-get install -y apache2 php5 libapache2-mod-php5 gpac motion zip

	fn_rpicamdir
	fn_webport
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
          cat etc/apache2/sites-available/default.1 > etc/apache2/sites-available/default
        else
          sed -e "s/Directory \/var\/www/Directory \/var\/www\/$rpicamdir/" etc/apache2/sites-available/default.1 > etc/apache2/sites-available/default
        fi
        sudo cp -r etc/apache2/sites-available/default /etc/apache2/sites-available/
        sudo chmod 644 /etc/apache2/sites-available/default
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
        sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
        sudo cp -r etc/raspimjpeg/raspimjpeg /etc/
        sudo chmod 644 /etc/raspimjpeg
        if [ ! -e /var/www/$rpicamdir/raspimjpeg ]; then
          sudo ln -s /etc/raspimjpeg /var/www/$rpicamdir/raspimjpeg
        fi


        if [ "$rpicamdir" == "" ]; then
          cat etc/rc_local_run/rc.local.1 > etc/rc_local_run/rc.local
        else
          sed -e "s/\/var\/www/\/var\/www\/$rpicamdir/" etc/rc_local_run/rc.local.1 > etc/rc_local_run/rc.local
        fi
        sudo cp -r /etc/rc.local /etc/rc.local.bak
        sudo cp -r etc/rc_local_run/rc.local /etc/
        sudo chmod 755 /etc/rc.local

        if [ "$rpicamdir" == "" ]; then
          cat etc/motion/motion.conf.1 > etc/motion/motion.conf
        else
          sed -e "s/www/www\/$rpicamdir/" etc/motion/motion.conf.1 > etc/motion/motion.conf
        fi
        sudo cp -r etc/motion/motion.conf /etc/motion/
        if [ ! "$rpicamdir" == "" ]; then
  	  sed -i "s/^netcam_url.*/netcam_url http:\/\/localhost\/$rpicamdir\/cam_pic.php/g" /etc/motion/motion.conf
        fi
        sudo chgrp www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf
        sudo usermod -a -G video www-data
        if [ -e /var/www/$rpicamdir/uconfig ]; then
          sudo chown www-data:www-data /var/www/$rpicamdir/uconfig
        fi
        
        if [ ! "$rpicamdir" == "" ]; then
          sed -i "s/www\//www\/$rpicamdir\//g" /var/www/$rpicamdir/schedule.php
        fi

        $color_green; echo "Installer finished"; $color_reset
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
          cat etc/nginx/sites-available/rpicam.1 > etc/nginx/sites-available/rpicam
        else
          sed -e "s:root /var/www;:root /var/www/$rpicamdir;:g" etc/nginx/sites-available/rpicam.1 > etc/nginx/sites-available/rpicam
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
          cat etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
        else
          sed -e "s/www/www\/$rpicamdir/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
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


        if [ "$rpicamdir" == "" ]; then
          cat etc/rc_local_run/rc.local.1 > etc/rc_local_run/rc.local
        else
          sed -e "s/\/var\/www/\/var\/www\/$rpicamdir/" etc/rc_local_run/rc.local.1 > etc/rc_local_run/rc.local
        fi
        sudo cp -r /etc/rc.local /etc/rc.local.bak
        sudo cp -r etc/rc_local_run/rc.local /etc/
        sudo chmod 755 /etc/rc.local

        if [ "$rpicamdir" == "" ]; then
          cat etc/motion/motion.conf.1 > etc/motion/motion.conf
        else
          sed -e "s/www/www\/$rpicamdir/" etc/motion/motion.conf.1 > etc/motion/motion.conf
        fi
        sudo cp -r etc/motion/motion.conf /etc/motion/
        if [ ! "$rpicamdir" == "" ]; then
  	  sed -i "s/^netcam_url.*/netcam_url http:\/\/localhost\/$rpicamdir\/cam_pic.php/g" /etc/motion/motion.conf
        fi
        sudo chgrp www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf
        sudo usermod -a -G video www-data
        if [ -e /var/www/$rpicamdir/uconfig ]; then
          sudo chown www-data:www-data /var/www/$rpicamdir/uconfig
        fi
        
        if [ ! "$rpicamdir" == "" ]; then
          sed -i "s/www\//www\/$rpicamdir\//g" /var/www/$rpicamdir/schedule.php
        fi

        # Restart nginx and php5-fpm to apply changes
        service nginx restart
        service php5-fpm restart

        $color_green; echo "Installer finished"; $color_reset
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
	fn_webport
        sudo cp -r bin/raspimjpeg /opt/vc/bin/
        sudo chmod 755 /opt/vc/bin/raspimjpeg
        sudo cp -r www/* /var/www/$rpicamdir/

        if [ ! -e /var/www/$rpicamdir/raspimjpeg ]; then
          sudo ln -s /etc/raspimjpeg /var/www/$rpicamdir/raspimjpeg
        fi
        sudo chmod 755 /var/www/$rpicamdir/raspizip.sh

        $color_green; echo "Upgrade finished"; $color_reset
        ;;

  start)
        fn_stop
        fn_rpicamdir
        sudo mkdir -p /dev/shm/mjpeg
        sudo chown www-data:www-data /dev/shm/mjpeg
        sudo chmod 777 /dev/shm/mjpeg
        sleep 1;sudo su -c 'raspimjpeg > /dev/null &' www-data
        sleep 1;sudo su -c "php /var/www/$rpicamdir/schedule.php > /dev/null &" www-data
        $color_green; echo "Started"; $color_reset
        ;;

  debug)
        fn_stop
        fn_rpicamdir
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
        echo "Usage: ./RPi_Cam_Web_Interface_Installer.sh {install|install_nginx|update|upgrade|remove|remove_nginx|start|stop|autostart_yes|autostart_no|debug}"; $color_reset
        ;;

esac

