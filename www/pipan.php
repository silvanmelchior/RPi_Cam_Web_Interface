<?php
   define('BASE_DIR', dirname(__FILE__));
   define('SERVO_CMD', '/dev/servoblaster');  
   define('SERVO_DATA', 'servo_on');  
   //
   // pipansettings
   //
   $min_pan = 50;
   $max_pan = 250;
   $min_tilt = 80;
   $max_tilt = 220;
   //
   // servo default settings
   //
   $servoData = array(
   'x' => 165,
   'y' => 165,
   'left' => 'Xplus',
   'right' => 'Xminus',
   'up' => 'Yminus',
   'down' => 'Yplus',
   'XMax' => 235,
   'XMin' => 95,
   'XStep' => 7,
   'YMax' => 235,
   'YMin' => 95,
   'YStep' => 7
   );

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
      try {
         $input = json_decode(file_get_contents(BASE_DIR . '/' . SERVO_DATA), true);
         foreach($servoData as $key => $value) {
            if (array_key_exists($key, $input)) {
               $servoData[$key] = $input[$key];
            }
         }
      } catch (Exception $e) {
      }
    
      $servo = '';
      $action = $_GET["action"];
      if (array_key_exists($action, $servoData)) {
         $action = $servoData[$action];
      }
    
      switch ($action) {
         case 'Xplus':
            $servoData['x'] += $servoData['XStep'];
            $servoData['x'] = min($servoData['x'], $servoData['XMax']);
            $servo = '1=' . $servoData['x'] . "\n";
            break;
         case 'Xminus':
            $servoData['x'] -= $servoData['XStep'];
            $servoData['x'] = max($servoData['x'], $servoData['XMin']);
            $servo = '1=' . $servoData['x'] . "\n";
            break;
         case 'Yminus':
            $servoData['y'] -= $servoData['YStep'];
            $servoData['y'] = max($servoData['y'], $servoData['YMin']);
            $servo = '0=' . $servoData['y'] . "\n";
            break;
         case 'Yplus':
            $servoData['y'] += $servoData['YStep'];
            $servoData['y'] = min($servoData['y'], $servoData['YMax']);
            $servo = '0=' . $servoData['y'] . "\n";
            break;
      }
      if ($servo != '') {
         $fs = fopen(SERVO_CMD, "w");
         fwrite($fs, $servo);
         fclose($fs);
      }
      file_put_contents(BASE_DIR . '/' . SERVO_DATA, json_encode($servoData));
   }
 
?>
