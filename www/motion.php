<!DOCTYPE html>
<?php
   define('BASE_DIR', dirname(__FILE__));
   require_once(BASE_DIR.'/config.php');

   //Text labels here
   define('BTN_SAVE', 'Save Settings');
   define('BTN_SHOWALL', 'Show All');
   define('BTN_SHOWLESS', 'Show Less');
   define('BTN_BACKUP', 'Backup');
   define('BTN_RESTORE', 'Restore');
   
   define('MOTION_URL', "http://127.0.0.1:6642/0/");
   
   define('MOTION_CONFIGBACKUP', "motionPars.json");
   define('MOTION_PARS', "motionPars");
   
   $filterPars = array("switchfilter","threshold","threshold_tune","noise_level","noise_tune","despeckle","despeckle_filter","area_detect","mask_file","smart_mask_speed","lightswitch","minimum_motion_frames","framerate","minimum_frame_time","netcam_url","netcam_userpass","gap","event_gap","on_event_start","on_event_end","on_motion_detected","on_area_detected");
   
   $motionReady = checkMotion();
   $showAll = false;
   $debugString = "";

   if ($motionReady) {
      $motionConfig = file_get_contents(MOTION_URL . "config/list");
      $motionPars = parse_ini_string($motionConfig, False, INI_SCANNER_RAW);
      
      //Process any POST data
      if(isset($_POST['action'])) {
         switch($_POST['action']) {
            case 'save':
               $changed = false;
               foreach($_POST as $key => $value) {
                  if (array_key_exists($key, $motionPars)) {
                     if ($value != $motionPars[$key]) {
                        setMotionPar($key, $value);
                        $changed = true;
                     }
                  }
               }
               if ($changed) {
                  writeMotionPars();
                  $motionConfig = restartMotion();
                  $motionPars = parse_ini_string($motionConfig, False, INI_SCANNER_RAW);
               }
               break;
            case 'showAll':
                  $showAll = true;
               break;
            case 'backup':
               $backup = array();
               $backup[MOTION_PARS] = $motionPars;
               $fp = fopen(MOTION_CONFIGBACKUP, 'w');
               fwrite($fp, json_encode($backup));
               fclose($fp);
               break;
            case 'restore':
                  if (file_exists(MOTION_CONFIGBACKUP)) {
                     $restore = json_decode(file_get_contents(MOTION_CONFIGBACKUP));
                     $motionPars = $restore[MOTION_PARS];
                     foreach ($motionPars as $mKey => $mValue) {
                        setMotionPar($mKey, $mValue);
                     }
                     writeMotionPars();
                     restartMotion();
                  }
               break;
         }
      }
   }
   
   function checkMotion() {
      $pids = array();
      exec("pgrep motion", $pids);
      if (empty($pids)) {
         return false;
      } else {
         return true;
      }
   }
   
   function setMotionPar($k, $v) {
      global $debugString;
   
      $t = file_get_contents(MOTION_URL . "config/set?" . $k ."=" . urlencode($v)); 
   }
   
   function writeMotionPars() {
      $t = file_get_contents(MOTION_URL . "config/write"); 
   }

   function pauseMotion() {
      $t = file_get_contents(MOTION_URL . "detection/pause");
   }

   function startMotion() {
      $t = file_get_contents(MOTION_URL . "detection/start");
   }

   //restart and fetch updated config list
   function restartMotion() {
      $t = file_get_contents(MOTION_URL . "action/restart");
      $retry = 20;
      do {
         sleep(1);
         $t = file_get_contents(MOTION_URL . "config/list");
         if ($t) {
            return $t;
         }
         $retry--;
      } while ($retry > 0);
   }

   function buildParsTable($pars, $fPars, $f) {
      echo '<table class="settingsTable">';
      foreach ($pars as $mKey => $mValue) {
         if ($f || in_array($mKey, $fPars)) {
            echo "<tr><td>$mKey</td><td><input type='text' autocomplete='off' size='50' name='$mKey' value='" . htmlspecialchars($mValue, ENT_QUOTES) . "'/></td></tr>";
         }
      }
      echo "</table>";
   }
?>
<html>
   <head>
      <meta name="viewport" content="width=550, initial-scale=1">
      <title>RPi Cam Download</title>
      <link rel="stylesheet" href="css/style_minified.css" />
      <link rel="stylesheet" href="css/preview.css" />
      <link rel="stylesheet" href="<?php echo getStyle(); ?>" />
      <script src="js/style_minified.js"></script>
   </head>
   <body>
      <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
         <div class="container">
            <div class="navbar-header">
               <a class="navbar-brand" href="<?php echo ROOT_PHP; ?>"><span class="glyphicon glyphicon-chevron-left"></span>Back - <?php echo CAM_STRING; ?></a>
            </div>
         </div>
      </div>
    
      <div class="container-fluid">
      <form action="motion.php" method="POST">
      <?php
      if ($debugString) echo $debugString . "<br>";
      echo '<div class="container-fluid text-center">';
      if ($showAll) {
         echo "<button class='btn btn-primary' type='submit' name='action' value='showLess'>" . BTN_SHOWLESS . "</button>";
      } else {
         echo "<button class='btn btn-primary' type='submit' name='action' value='showAll'>" . BTN_SHOWALL . "</button>";
      }
      echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='save'>" . BTN_SAVE . "</button>";
      echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='backup'>" . BTN_BACKUP . "</button>";
      echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='restore'>" . BTN_RESTORE . "</button><br><br>";
      echo '</div>';
      if ($motionReady) {
         buildParsTable($motionPars, $filterPars, $showAll);
      } else {
         echo "<h1>Motion not running. Put in detection state</h1>";
      }
      ?>
      </form>
      </div>
   </body>
</html>
