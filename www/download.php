<?php

  if(substr($_GET["file"], -3) == "jpg") header("Content-Type: image/jpeg");
  else header("Content-Type: video/mp4");
  header("Content-Disposition: attachment; filename=\"" . basename($_GET["file"]) . "\"");
  readfile("media/" . basename($_GET["file"]));

?>
