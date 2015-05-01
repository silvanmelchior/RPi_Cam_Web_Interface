Added a pan-tilt control (based in ServoBlaster) in the web-interface from 

Depends on ServoBlaster to move the servos, so you should install it first https://github.com/richardghirst/PiBits/tree/master/ServoBlaster

Once ServoBlaster is installed and working, just follow the instructions;

sudo apt-get update

sudo apt-get dist-upgrade

sudo rpi-update

git clone https://github.com/skalad/RPi_Cam_Web_Interface.git

cd RPi_Cam_Web_Interface

chmod u+x RPi_Cam_Web_Interface_Installer.sh

./RPi_Cam_Web_Interface_Installer.sh install

After the setup finishes, you have to restart your RPi. Now just open up any browser on any computer in your network and enter the IP of the RPi as URL.
