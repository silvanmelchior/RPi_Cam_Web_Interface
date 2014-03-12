<?php

  // send content
  $file_content = "";
  for($i=0; $i<30; $i++) {
    $file_content = file_get_contents("status_mjpeg.txt");
    if($file_content != $_GET["last"]) break;
    usleep(100000);
  }
  echo $file_content;

?>
