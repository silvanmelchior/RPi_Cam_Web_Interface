![Alt text](/pic2.jpg?raw=true)
Added a pan-tilt control (moving the sevos by software with ServoBlaster) in the web-interface from https://github.com/silvanmelchior/RPi_Cam_Web_Interface

By default is configured for using GPIO4 and GPIO17. It can be modified if needed by modifiying the up.sh down.sh right.sh left.sh scripts from directory /var/www/

![Alt text](/pic.jpg?raw=true)
Depends on ServoBlaster to move the servos, so you should install it first https://github.com/richardghirst/PiBits/tree/master/ServoBlaster

For Raspberry Pi 2 this is the only working version of ServoBlaster I found; https://www.raspberrypi.org/forums/viewtopic.php?p=699651&sid=c399f7fc62b79016f7678a4f73e6c1f4#p699651

Once ServoBlaster is installed and working, just follow the instructions like in the original RPi-Cam-Web-Interface but using this git repository.

sudo apt-get update

sudo apt-get dist-upgrade

sudo rpi-update

git clone https://github.com/skalad/RPi_Cam_Web_Interface_ServoBlaster_pan_tilt

cd RPi_Cam_Web_Interface

chmod u+x RPi_Cam_Web_Interface_Installer.sh

./RPi_Cam_Web_Interface_Installer.sh install

After the setup finishes, you have to restart your RPi. Now just open up any browser on any computer in your network and enter the IP of the RPi as URL.

