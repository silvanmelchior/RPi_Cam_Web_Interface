<?php
 
  //
  // settings
  //
  $min_pan = 60;
  $max_pan = 190;
  $min_tilt = 120;
  $max_tilt = 220;
 
 
  //
  // code
  //
  if(isset($_GET["pan"])) {
    if(is_numeric($_GET["pan"])) {
      if(is_numeric($_GET["tilt"])) {
        $pan = round($min_pan + (($max_pan - $min_pan)/200*$_GET["pan"]));
        $tilt = round($min_tilt + (($max_tilt - $min_tilt)/200*$_GET["tilt"]));
        $pipe = fopen("FIFO_pipan","w");
        fwrite($pipe, "servo $pan $tilt ");
        fclose($pipe);
      }
    }
  }
 
  if(isset($_GET["red"])) {
    if(is_numeric($_GET["red"])) {
      if(is_numeric($_GET["green"])) {
        if(is_numeric($_GET["blue"])) {
          $pipe = fopen("FIFO_pipan","w");
          fwrite($pipe, "led " . $_GET["red"] . " " . $_GET["green"] . " " . $_GET["blue"] . " ");
          fclose($pipe);
        }
      }
    }
  }
 
?>