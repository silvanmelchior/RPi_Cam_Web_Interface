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
rpicamdir=""

cd $(dirname $(readlink -f $0))

	if [ "$rpicamdir" == "" ]; then
		echo "Please input directory name where you want to install RPi_Cam_Web_Interface."
		echo "Leave it empty for using www root."
		read rpicamdir
	fi
	
fn_stop ()
{ # This is function stop
        sudo killall raspimjpeg
        sudo killall php
        sudo killall motion
        echo "Stopped"
}

case "$1" in

  remove)
        sudo killall raspimjpeg
        sudo apt-get remove -y apache2 php5 libapache2-mod-php5 gpac motion zip
        sudo apt-get autoremove -y

        sudo rm -r /var/www/$rpicamdir/*
        sudo rm /etc/sudoers.d/RPI_Cam_Web_Interface
        sudo rm /usr/bin/raspimjpeg
        sudo rm /etc/raspimjpeg
        sudo cp -r /etc/rc.local.bak /etc/rc.local
        sudo chmod 755 /etc/rc.local

        echo "Removed everything"
        ;;

  autostart_yes)
        sudo cp -r etc/rc_local_run/rc.local /etc/
        sudo chmod 755 /etc/rc.local
        echo "Changed autostart"
        ;;

  autostart_no)
        sudo cp -r /etc/rc.local.bak /etc/rc.local
        sudo chmod 755 /etc/rc.local
        echo "Changed autostart"
        ;;

  install)
        sudo killall raspimjpeg
        git pull origin master
        sudo apt-get install -y apache2 php5 libapache2-mod-php5 gpac motion zip

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
          echo "Your custom raspimjpg backed up at /etc/raspimjpeg.bak"
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
        sudo chgrp www-data /etc/motion/motion.conf
        sudo chmod 664 /etc/motion/motion.conf
        sudo usermod -a -G video www-data
        if [ -e /var/www/$rpicamdir/uconfig ]; then
          sudo chown www-data:www-data /var/www/$rpicamdir/uconfig
        fi

        echo "Installer finished"
        ;;

  update)
        sudo killall raspimjpeg
        git pull origin master
        sudo apt-get install -y zip

        sudo cp -r bin/raspimjpeg /opt/vc/bin/
        sudo chmod 755 /opt/vc/bin/raspimjpeg
        sudo cp -r www/* /var/www/$rpicamdir/

        if [ ! -e /var/www/$rpicamdir/raspimjpeg ]; then
          sudo ln -s /etc/raspimjpeg /var/www/$rpicamdir/raspimjpeg
        fi
        sudo chmod 755 /var/www/$rpicamdir/raspizip.sh

        echo "Update finished"
        ;;

  start)
        fn_stop
        sudo mkdir -p /dev/shm/mjpeg
        sudo chown www-data:www-data /dev/shm/mjpeg
        sudo chmod 777 /dev/shm/mjpeg
        sleep 1;sudo su -c 'raspimjpeg > /dev/null &' www-data
        sleep 1;sudo su -c "php /var/www/$rpicamdir/schedule.php > /dev/null &" www-data
        echo "Started"
        ;;

  debug)
        fn_stop
        sudo mkdir -p /dev/shm/mjpeg
        sudo chown www-data:www-data /dev/shm/mjpeg
        sudo chmod 777 /dev/shm/mjpeg
        sleep 1;sudo su -c 'raspimjpeg &' www-data
        sleep 1;sudo sudo su -c "php /var/www/$rpicamdir/schedule.php &" www-data
        echo "Started with debug"
        ;;

  stop)
        fn_stop
        ;;

  *)
        echo "No or invalid option selected"
        echo "Usage: ./RPi_Cam_Web_Interface_Installer.sh {install|update|remove|start|stop|autostart_yes|autostart_no|debug}"
        ;;

esac

