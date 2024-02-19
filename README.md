Installation:
Tested on Raspbian GNU/Linux 9.6 (stretch) on Raspberry Pi 3 and Zero

1. Clone or download and unzip the repo.

2. cd into the directory
<pre>
cd RPi_Cam_Web_Interface
</pre>

3. Run the install script
<pre>
sudo ./install.sh
</pre>

Notes: The nginx server seems to work better than apache2.  If you get an mmal error, 
the first thing to check is the cable connecting the camera to your Pi.



Web based interface for controlling the Raspberry Pi Camera, includes motion detection, time lapse, and image and video recording.
Current version 6.6.26
All information on this project can be found here: http://www.raspberrypi.org/forums/viewtopic.php?f=43&t=63276

The wiki page can be found here:

http://elinux.org/RPi-Cam-Web-Interface

This includes the installation instructions at the top and full technical details.
For latest change details see:

https://github.com/silvanmelchior/RPi_Cam_Web_Interface/commits/master
  
This version has updates for php7.3 / Buster. May need further changes for nginx