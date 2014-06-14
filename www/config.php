<?php
  
  // name of this application
  define('APP_NAME', 'RPi Cam Control');
  
  // the host running the application
  define('HOST_NAME', php_uname('n'));
  
  // name of this camera
  define('CAM_NAME', 'mycam');
  
  // unique camera string build from application name, camera name, host name
  define('CAM_STRING', APP_NAME . ": " . CAM_NAME . '@' . HOST_NAME);

?>
