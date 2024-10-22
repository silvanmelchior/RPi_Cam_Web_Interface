Installation
-----

### Step 1: Install dependencies + [rpicam-mjpeg](https://github.com/consiliumsolutions/p05a-rpicam-apps)
```bash
cd RPi_Cam_Web_Interface
bin/install-rpicam-mjpeg.sh
```

### Step 2: Install the web application
```bash
./install.sh
```

### Step 3: Run the web application + rpicam-mjpeg
```bash
./start.sh
```
NOTE: When you run this command, you may encounter error: `bash: line 1: /usr/bin/raspimjpeg: cannot execute: required file not found`, this is due to historical reasons, which can be safely ignored.

Finally, visit our program at: http://localhost/html/ and start using it!

-----

Web based interface for controlling the Raspberry Pi Camera, includes motion detection, time lapse, and image and video recording.
Current version 6.6.26
All information on this project can be found here: http://www.raspberrypi.org/forums/viewtopic.php?f=43&t=63276

The wiki page can be found here:

http://elinux.org/RPi-Cam-Web-Interface

This includes the installation instructions at the top and full technical details.
For latest change details see:

https://github.com/silvanmelchior/RPi_Cam_Web_Interface/commits/master
  
This version has updates for php7.3 / Buster. May need further changes for nginx
