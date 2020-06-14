<?php
  header("Access-Control-Allow-Origin: *");
  header("Content-Type: image/jpeg");
   if (isset($_GET["pDelay"]))
   {
      $preview_delay = $_GET["pDelay"];
   } else {
      $preview_delay = 10000;
   }
   usleep($preview_delay);
   readfile("/dev/shm/mjpeg/cam.jpg");

?>
