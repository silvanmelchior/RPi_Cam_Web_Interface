<?php
   //Global defines and utility functions
   // version string
   define('APP_VERSION', 'v4.4.2R');

   // name of this application
   define('APP_NAME', 'RPi Cam Control');

   // the host running the application
   define('HOST_NAME', php_uname('n'));

   // name of this camera
   define('CAM_NAME', 'mycam');

   // unique camera string build from application name, camera name, host name
   define('CAM_STRING', APP_NAME . " " . APP_VERSION . ": " . CAM_NAME . '@' . HOST_NAME);

   // file where default settings changes are stored
   define('CONFIG_FILE1', 'raspimjpeg');

   // file where user specific settings changes are stored
   define('CONFIG_FILE2', 'uconfig');

   // file where user specific settings changes are stored
   define('MEDIA_PATH', 'media');
   
   // character used to flatten file paths
   define('SUBDIR_CHAR', '@');
   
   // file where a debug file is stored
   define('LOGFILE_DEBUG', 'debugLog.txt');

   // file where schedule log is stored
   define('LOGFILE_SCHEDULE', 'scheduleLog.txt');

   // debug log function
   function writeDebugLog($msg) {
      $log = fopen(LOGFILE_DEBUG, 'a');
      $time = date('[Y/m/d H:i:s]');
      fwrite($log, "$time $msg" . PHP_EOL);
      fclose($log);
   }

   // schedule log function
   function writeLog($msg) {
      $log = fopen(LOGFILE_SCHEDULE, 'a');
      $time = date('[Y/m/d H:i:s]');
      fwrite($log, "$time $msg" . PHP_EOL);
      fclose($log);
   }

   // functions to read and save config data
   function readConfig($config, $configFile) {
      if (file_exists($configFile)) {
         $lines = array();
         $data = file_get_contents($configFile);
         $lines = explode("\n", $data);
         foreach($lines as $line) {
            if (strlen($line) && substr($line, 0, 1) != '#') {
               $index = strpos($line, ' ');
               if ($index !== false) {
                  $key = substr($line, 0, $index);
                  $value = trim(substr($line, $index +1));
                  $config[$key] = $value;
               }
            }
         }
      }
      return $config;
   }

   function saveUserConfig($config) {
      $cstring= "";
      foreach($config as $key => $value) {
         $cstring .= $key . ' ' . $value . "\n";
      }
      if (cstring != "") {
         $fp = fopen(CONFIG_FILE2, 'w');
         fwrite($fp, "#User config file\n");
         fwrite($fp, $cstring);
         fclose($fp);
      }
   }

   // functions to find and delete data files
   function dataFilename($file) {
      return str_replace(SUBDIR_CHAR, '/', substr($file, 0 , -13));
   }
   
   function findLapseFiles($d) {
      //return an arranged in time order and then must have a matching 4 digit batch and an incrementing lapse number
      $batch = sprintf('%04d', substr($d, -11, 4));
      $fullname = MEDIA_PATH . '/' . dataFilename($d);
      $path = dirname($fullname);
      $start = filemtime("$fullname");
      $files = array();
      $scanfiles = scandir($path);
      $lapsefiles = array();
      foreach($scanfiles as $file) {
         if (strpos($file, $batch) !== false) {
            if (strpos($file, '.th.jpg') === false) {
               $fDate = filemtime("$path/$file");
               if ($fDate >= $start) {
                  $files[$file] = $fDate;
               }
            }
         }
      }
      asort($files);
      $lapseCount = 1;
      foreach($files as $key => $value) {
         if (strpos($key, sprintf('%04d', $lapseCount)) !== false) {
            $lapsefiles[] = "$path/$key";
            $lapseCount++;
         } else {
            break;   
         }
      }
      return $lapsefiles;
   }

   //function to delete all files associated with a thumb name
   function deleteFile($d) {
      $t = substr($d,-12, 1); 
      if ($t == 't') {
         // For time lapse try to delete all from this batch
         
         //get file list in time order
         $files = findLapseFiles($d);
         foreach($files as $file) {
            if(!unlink($file)) $debugString .= "F ";
         }
      } else {
         $tFile = dataFilename($d);
         if (file_exists(MEDIA_PATH . "/$tFile")) {
            unlink(MEDIA_PATH . "/$tFile");
         }
      }
      unlink(MEDIA_PATH . "/$d");
   }
?>
