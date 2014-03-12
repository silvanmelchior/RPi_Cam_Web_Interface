BETA
====

THIS REPOSITORY IS NOT ACTUAL AND CORRECT YET, THE REAL VERSION IS HERE: http://www.raspberrypi.org/phpBB3/viewtopic.php?f=43&t=63276

RPi_Cam_Browser_Control
=======================

Raspberry Pi Camera control, feed and motion capture

This code is taken from Silvan Melchior and modified to sit around a git repository rather than downloads of tarballs.

I believe this is a better way of hosting the project and also am going to look to build in an update mechanism.

Installation
============
On a clean Raspbian image with a camera attached

Run through the following steps to update the OS and firmware:

sudo apt-get update

sudo apt-get dist-upgrade

sudo rpi-update


clone this repository

git clone https://github.com/jfarcher/RPi_Cam_Browser_Control.git

cd RPi_Cam_Browser_Control

./RPi_Cam_Browser_Control.sh install

This will run through a process of installing various packages and copying files into their relevant locations.

Once this has completed you have a few options:

./RPi_Cam_Browser_Control_Installer.sh autostart_run --> the interface starts at startup and takes control over the camera (standard)

./RPi_Cam_Browser_Control_Installer.sh autostart_md --> the interface starts at startup with motion detection activated

./RPi_Cam_Browser_Control_Installer.sh autostart_idle --> the interface starts at startup, but waits until you push the button "start camera" on the website to take control over the camera

./RPi_Cam_Browser_Control_Installer.sh autostart_no --> the interface doesn't start at startup, you need to run a command to use it (commands below) 

Reboot your Pi

Now put the IP of your Pi into your Browser.

The following forum post follows the original developer and the progress, of which will be reflected in this git repository.

Browser Compatiblity: Internet Explorer isn't supported, Opera and Firefox <21 can't show the preview of recorded videos.

Motion Detection: To configure motion detection, edit /etc/motion/motion.conf. Motion detection is not active while the old video is converted to mp4. To prevent this, stop boxing the h264-video after recording by removing the -p parameter for raspimjpeg in /etc/rc.local and restart your RPi.

Temporarily start/stop and deinstallation: Navigate back to the git repository. If you want to stop the interface temporarily, run "./RPi_Cam_Browser_Control_Installer.sh stop". To restart it, run "./RPi_Cam_Browser_Control_Installer.sh start".

If you want to remove the interface completely, run "./RPi_Cam_Browser_Control_Installer.sh remove". Attention: It removes all files in /var/www.

Source Code: After installation, the source code for the installer is where you cloned, the source code for the interface itself is in www and the source code for the autostart is in etc/rc.local. The whole project is based on Silvans other project called RaspiMJPEG, more information here: http://www.raspberrypi.org/phpBB3/viewtopic.php?f=43&t=61771 , source code here: 
https://github.com/silvanmelchior/userland/blob/master/host_applications/linux/apps/raspicam/RaspiMJPEG.c

Embed in own homepage: If you want to add the live-preview to your homepage, here are the instructions:
- Navigate to /var/www
- Remove all files except cam_pic.php, script_min.js and FIFO
- Copy your own homepage into /var/www
- Change your index.html/php: Add script_min.js (<script src="script_min.js"></script> in header)
- Change your index.html/php: Add onload="setTimeout('init();', 100);" to body
- Change your index.html/php: Add <img id="mjpeg_dest"> at the place where you want the live-preview.
The size can be changed either as parameter in /etc/rc.local or with CSS. To add further features (change settings, record images/videos), study the existing homepage.

