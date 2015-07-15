<?php
  define('BASE_DIR', dirname(__FILE__));
  define('SERVO_CMD', '/dev/servoblaster');  
  define('SERVO_COORDINATES', 'servo_on');  
  //
  // pipansettings
  //
  $min_pan = 50;
  $max_pan = 250;
  $min_tilt = 80;
  $max_tilt = 220;
 
 
  //
  // code for pipan
  //
  if(isset($_GET["pan"])) {
    if(is_numeric($_GET["pan"])) {
      if(is_numeric($_GET["tilt"])) {
        $pan = round($min_pan + (($max_pan - $min_pan)/200*$_GET["pan"]));
        $tilt = round($min_tilt + (($max_tilt - $min_tilt)/200*$_GET["tilt"]));
        $pipe = fopen("FIFO_pipan","w");
        fwrite($pipe, "servo $pan $tilt ");
        fclose($pipe);
        file_put_contents("pipan_bak.txt", $_GET["pan"] . " " . $_GET["tilt"]);
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
  //
  // code for servo
  //
  if(isset($_GET["action"])) {
    $coordinates = json_decode(file_get_contents(BASE_DIR . '/' . SERVO_COORDINATES), true);
    $servo = '';
    if (!array_key_exists('x', $coordinates) || !array_key_exists('y', $coordinates)) {
       $coordinates = array();
       $coordinates['x'] = 165;
       $coordinates['y'] = 165;
    }
    switch ($_GET["action"]) {
       case 'left':
         $coordinates['x'] += 7;
         if ($coordinates['x'] > 235) $coordinates['x'] = 235;
         $servo = '1=' . $coordinates['x'] . "\n";
         break;
       case 'right':
         $coordinates['x'] -= 7;
         if ($coordinates['x'] < 95) $coordinates['x'] = 95;
         $servo = '1=' . $coordinates['x'] . "\n";
         break;
       case 'up':
         $coordinates['y'] -= 7;
         if ($coordinates['y'] < 95) $coordinates['y'] = 95;
         $servo = '0=' . $coordinates['y'] . "\n";
         break;
       case 'down':
         $coordinates['y'] += 7;
         if ($coordinates['y'] > 235) $coordinates['y'] = 235;
         $servo = '0=' . $coordinates['y'] . "\n";
         break;
    }
    if ($servo != '') {
       $fs = fopen(SERVO_CMD, "w");
       fwrite($fs, $servo);
       fclose($fs);
    }
    file_put_contents(BASE_DIR . '/' . SERVO_COORDINATES, json_encode($coordinates));
  }
 
?>
