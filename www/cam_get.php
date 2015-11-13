<?php

   touch("status_mjpeg.txt");
   header("Content-Type: image/jpeg");
   readfile("/dev/shm/mjpeg/cam.jpg");

?>
