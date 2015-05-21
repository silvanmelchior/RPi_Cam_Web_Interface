<?php
   //Local define of base diretory for routines here
   define('LBASE_DIR',dirname(__FILE__));
   //Global defines and utility functions
   // version string
   define('APP_VERSION', 'v6.0.1');

   // name of this application
   define('APP_NAME', 'RPi Cam Control');

   // the host running the application
   define('HOST_NAME', php_uname('n'));
   
   //define main starting php
   define('ROOT_PHP', 'index.php');

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

   // character used to flatten file paths
   define('THUMBNAIL_EXT', '.th.jpg');
   
   // file where a debug file is stored
   define('LOGFILE_DEBUG', 'debugLog.txt');

   // file where schedule log is stored
   define('LOGFILE_SCHEDULE', 'scheduleLog.txt');

   // debug log function
   function writeDebugLog($msg) {
      $log = fopen(LBASE_DIR . '/' . LOGFILE_DEBUG, 'a');
      $time = date('[Y/m/d H:i:s]');
      fwrite($log, "$time $msg" . PHP_EOL);
      fclose($log);
   }

   // schedule log function
   function writeLog($msg) {
      $log = fopen(LBASE_DIR . '/' . LOGFILE_SCHEDULE, 'a');
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
         $fp = fopen(LBASE_DIR . '/' . CONFIG_FILE2, 'w');
         fwrite($fp, "#User config file\n");
         fwrite($fp, $cstring);
         fclose($fp);
      }
   }

   // functions to find and delete data files
   
   function getSortedFiles($ascending = true) {
      $scanfiles = scandir(LBASE_DIR . '/' . MEDIA_PATH);
      $files = array();
      foreach($scanfiles as $file) {
         if(($file != '.') && ($file != '..') && isThumbnail($file)) {
            $fDate = filemtime(MEDIA_PATH . "/$file");
            $files[$file] = $fDate;
         } 
      }
      if ($ascending)
         asort($files);
      else
         arsort($files);
      return array_keys($files);
   }
   
   function findLapseFiles($d) {
      //return an arranged in time order and then must have a matching 4 digit batch and an incrementing lapse number
      $batch = getFileIndex($d);
      $padlen = strlen($batch);
      $fullname = LBASE_DIR . '/' . MEDIA_PATH . '/' . dataFilename($d);
      $path = dirname($fullname);
      $start = filemtime("$fullname");
      $files = array();
      $scanfiles = scandir($path);
      $lapsefiles = array();
      foreach($scanfiles as $file) {
         if (strpos($file, $batch) !== false) {
            if (!isThumbnail($file)) {
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
         if (strpos($key, str_pad($lapseCount, $padlen, 0, STR_PAD_LEFT)) !== false) {
            $lapsefiles[] = "$path/$key";
            $lapseCount++;
         } else {
            break;   
         }
      }
      return $lapsefiles;
   }

   //function to delete all files associated with a thumb name
   //returns space freed in kB
   //if $del = false just calculate space which would be freed
   function deleteFile($d, $del = true) {
      $size = 0;
      $t = getFileType($d); 
      if ($t == 't') {
         // For time lapse try to delete all from this batch
         $files = findLapseFiles($d);
         foreach($files as $file) {
            $size += filesize($file);
            if ($del) if(!unlink($file)) $debugString .= "F ";
         }
      } else {
         $tFile = dataFilename($d);
         if (file_exists(LBASE_DIR . '/' . MEDIA_PATH . "/$tFile")) {
            $size += filesize(LBASE_DIR . '/' . MEDIA_PATH . "/$tFile");
            if ($del) unlink(LBASE_DIR . '/' . MEDIA_PATH . "/$tFile");
         }
      }
      $size += filesize(LBASE_DIR . '/' . MEDIA_PATH . "/$d");
      if ($del) unlink(LBASE_DIR . '/' . MEDIA_PATH . "/$d");
      return $size / 1024;
   }
   
   //Support naming functions
   function dataFilename($file) {
      $i = strrpos($file, '.', -8);
      if ($i !== false)
         return str_replace(SUBDIR_CHAR, '/', substr($file, 0, $i));
      else
         return ""; 
   }

   function dataFileext($file) {
      $f = dataFileName($file);
      if ($f <> "") {
         $i = strrpos($f, '.');
         if ($i !== false)
            return substr($f, $i+1);
      }
      return ""; 
   }

   function isThumbnail($file) {
      return (substr($file, -7) == THUMBNAIL_EXT);
   }
   
   function getFileType($file) {
      $i = strrpos($file, '.', -8);
      if ($i !== false)
         return substr($file, $i + 1, 1);
      else
         return ""; 
   }
   
   function getFileIndex($file) {
      $i = strrpos($file, '.', -8);
      if ($i !== false)
         return substr($file, $i + 2, strlen($file) - $i - 9);
      else
         return ""; 
   }

?>
