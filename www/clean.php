<!DOCTYPE html>
<?php
  define('BASE_DIR', dirname(__FILE__));
  require_once(BASE_DIR.'/config.php');
?>
<html>
  <head>
    <title><?php echo CAM_STRING; ?></title>
    <script src="script.js"></script>
  </head>
  <body onload="setTimeout('init();', 100);">
    <center>
      <div><img id="mjpeg_dest"></div>
    </center>
  </body>
</html>
