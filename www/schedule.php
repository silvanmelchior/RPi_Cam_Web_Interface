<?php
   define('BASE_DIR', dirname(__FILE__));
   require_once(BASE_DIR.'/config.php');
   //Text labels here
   define('BTN_START', 'Start');
   define('BTN_STOP', 'Stop');
   define('BTN_SAVE', 'Save Settings');
   define('BTN_BACKUP', 'Backup');
   define('BTN_RESTORE', 'Restore');
   define('BTN_SHOWLOG', 'Show Log');
   define('BTN_DOWNLOADLOG', 'Download Log');
   define('BTN_CLEARLOG', 'Clear Log');
   define('LBL_PERIODS', 'Night;Dawn;Day;Dusk');
   define('LBL_COLUMNS', 'Period;Motion Start;Motion Stop;Period Start');
   define('LBL_PARAMETERS', 'Parameter;Value');
   define('LBL_DAWN', 'Dawn');
   define('LBL_DAY', 'Day');
   define('LBL_DUSK', 'Dusk');

   define('SCHEDULE_CONFIG', 'schedule.json');
   define('SCHEDULE_CONFIGBACKUP', 'scheduleBackup.json');
 
   define('SCHEDULE_START', '1');
   define('SCHEDULE_STOP', '0');
   define('SCHEDULE_RESET', '9');
   
   define('SCHEDULE_ZENITH', '90.8');
 
   define('SCHEDULE_FIFOIN', 'Fifo_In');
   define('SCHEDULE_FIFOOUT', 'Fifo_Out');
   define('SCHEDULE_CMDPOLL', 'Cmd_Poll');
   define('SCHEDULE_MODEPOLL', 'Mode_Poll');
   define('SCHEDULE_MAXCAPTURE', 'Max_Capture');
   define('SCHEDULE_LATITUDE', 'Latitude');
   define('SCHEDULE_LONGTITUDE', 'Longtitude');
   define('SCHEDULE_GMTOFFSET', 'GMTOffset');
   define('SCHEDULE_DAWNSTARTMINUTES', 'DawnStart_Minutes');
   define('SCHEDULE_DAYSTARTMINUTES', 'DayStart_Minutes');
   define('SCHEDULE_DAYENDMINUTES', 'DayEnd_Minutes');
   define('SCHEDULE_DUSKENDMINUTES', 'DuskEnd_Minutes');
   define('SCHEDULE_ALLDAY', 'AllDay');
   define('SCHEDULE_DAYMODE', 'DayMode');
   define('SCHEDULE_FIXEDTIMES', 'FixedTimes');
   define('SCHEDULE_MANAGEMENTINTERVAL', 'Management_Interval');
   define('SCHEDULE_MANAGEMENTCOMMAND', 'Management_Command');
   define('SCHEDULE_PURGEVIDEOHOURS', 'PurgeVideo_Hours');
   define('SCHEDULE_PURGEIMAGEHOURS', 'PurgeImage_Hours');
   define('SCHEDULE_PURGELAPSEHOURS', 'PurgeLapse_Hours');
   define('SCHEDULE_COMMANDSON', 'Commands_On');
   define('SCHEDULE_COMMANDSOFF', 'Commands_Off');
   define('SCHEDULE_MODES', 'Modes');
   define('SCHEDULE_TIMES', 'Times');
   
   $debugString = "";
   $schedulePars = array();
   $schedulePars = loadPars(BASE_DIR . '/' . SCHEDULE_CONFIG);
   
   $cliCall = isCli();
   $logFile = BASE_DIR . '/' . LOGFILE_SCHEDULE;
   $showLog = false;
   $schedulePID = getSchedulePID();
   if (!$cliCall && isset($_POST['action'])) {
   //Process any POST data
      switch($_POST['action']) {
         case 'start':
            startSchedule();
            $schedulePID = getSchedulePID();
            break;
         case 'stop':
            stopSchedule($schedulePID);
            $schedulePID = getSchedulePID();
            break;
         case 'save':
            writeLog('Saved schedule settings');
            $fp = fopen(BASE_DIR . '/' . SCHEDULE_CONFIG, 'w');
            $saveData = $_POST;
            unset($saveData['action']);
            fwrite($fp, json_encode($saveData));
            fclose($fp);
            $schedulePars = loadPars(BASE_DIR . '/' . SCHEDULE_CONFIG);
            sendReset();
            break;
         case 'backup':
            writeLog('Backed up schedule settings');
            $fp = fopen(BASE_DIR . '/' . SCHEDULE_CONFIGBACKUP, 'w');
            fwrite($fp, json_encode($schedulePars));
            fclose($fp);
            break;
         case 'restore':
            writeLog('Restored up schedule settings');
            $schedulePars = loadPars(BASE_DIR . '/' . SCHEDULE_CONFIGBACKUP);
            break;
         case 'showlog':
            $showLog = true;
            break;
         case 'downloadlog':
            if (file_exists($logFile)) {
               header("Content-Type: text/plain");
               header("Content-Disposition: attachment; filename=\"" . date('Ymd-His-'). $schedulePars[SCHEDULE_LOGFILE] . "\"");
               readfile("$logFile");
               return;
            }
         case 'clearlog':
            if (file_exists($logFile)) {
               unlink($logFile);
            }
            break;
      }
   }
   
   function isCli() {
       if( defined('STDIN') ) {
           return true;
       }
       if( empty($_SERVER['REMOTE_ADDR']) and !isset($_SERVER['HTTP_USER_AGENT']) and count($_SERVER['argv']) > 0) {
           return true;
       } 
       return false;
   }
   
   function getSchedulePID() {
      $pids = array();
      exec("pgrep -f -l schedule.php", $pids);
      $pidId = 0;
      foreach($pids as $pid) {
         if (strpos($pid, 'php ') !== false) {
            $pidId = strpos($pid, ' ');
            $pidId = substr($pid, 0, $pidId);
            break;
         }
      }
      return $pidId;
   }
   
   function startSchedule() {
      $ret = exec("php schedule.php >/dev/null &");
   }

   function stopSchedule($pid) {
      exec("kill $pid");
   }
   function loadPars($config) {
      $pars = initPars();
      if (file_exists($config)) {
         try {
            //get pars from config file and update only values which exist in initPars
            $input = json_decode(file_get_contents($config), true);
            foreach($pars as $key => $value) {
               if (array_key_exists($key, $input)) {
                  $pars[$key] = $input[$key];
               }
            }
            if (array_key_exists(SCHEDULE_ALLDAY,$input)) $pars[SCHEDULE_DAYMODE] = '1';
         } catch (Exception $e) {
         }
      }
      return $pars;
   }

   function initPars() {
      $pars = array(
         SCHEDULE_FIFOIN => '/var/www/FIFO1',
         SCHEDULE_FIFOOUT => '/var/www/FIFO',
         SCHEDULE_CMDPOLL => '0.03',
         SCHEDULE_MODEPOLL => '10',
         SCHEDULE_MANAGEMENTINTERVAL => '3600',
         SCHEDULE_MANAGEMENTCOMMAND => '',
         SCHEDULE_PURGEVIDEOHOURS => '0',
         SCHEDULE_PURGEIMAGEHOURS => '0',
         SCHEDULE_PURGELAPSEHOURS => '0',
         SCHEDULE_GMTOFFSET => '0',
         SCHEDULE_DAWNSTARTMINUTES => '-180',
         SCHEDULE_DAYSTARTMINUTES => '0',
         SCHEDULE_DAYENDMINUTES => '0',
         SCHEDULE_DUSKENDMINUTES => '180',
         SCHEDULE_LATITUDE => '52.00',
         SCHEDULE_LONGTITUDE => '0.00',
         SCHEDULE_MAXCAPTURE => '30',
         SCHEDULE_DAYMODE => '0',
         SCHEDULE_TIMES => array("09:00","10:00","11:00","12:00","13:00","13:00"),
         SCHEDULE_COMMANDSON => array("","","ca 1",""),
         SCHEDULE_COMMANDSOFF => array("","","ca 0",""),
         SCHEDULE_MODES => array("md 0;em night","md 0;em night","md 0;em auto;md 1","md 0;em night")
      );
      return $pars;
   }

   //Support functions for HTML
   function showScheduleSettings($pars) {
      global $schedulePars;
      $headings = explode(';', LBL_PARAMETERS);
      echo '<table class="settingsTable">';
      echo '<tr>';
      foreach($headings as $heading) {
         echo '<th style="text-align:center">' . $heading . '</th>';
      }
      foreach($headings as $heading) {
         echo '<th style="text-align:center">' . $heading . '</th>';
      }
      echo '</tr>';
      $column = 0;
      foreach ($pars as $mKey => $mValue) {
         if ($column == 0) echo '<tr>';
         if (!is_array($mValue)) {
            if ($mKey == SCHEDULE_DAYMODE) {
               $dayOptions = array('Sun based','All Day','Fixed Times');
               echo "<td>$mKey&nbsp;&nbsp;</td><td>Select Day Mode&nbsp;<select id='$mKey' name='$mKey'" .' onclick="schedule_rows();">';
               for($i = 0; $i < 3; $i++) {
                  if ($i == $mValue) $selected = ' selected'; else $selected ='';
                  $dayOption = $dayOptions[$i];
                  echo "<option value='$i'$selected>$dayOption</option>";
               }
               echo '</select></td>';
            } else {
               echo "<td>$mKey&nbsp;&nbsp;</td><td><input type='text' autocomplete='off' size='30' name='$mKey' value='" . htmlspecialchars($mValue, ENT_QUOTES) . "'/></td>";
               
            }
            $column++;
            if ($column == 2) {echo '</tr>';$column =0;}
         }
      }
      if ($column == 0) echo '<tr>';
      echo '</table><br>';
      $d = dayPeriod();
      $periods = explode(';', LBL_PERIODS);
      if ($d < 4) $period = $periods[$d]; else $period = $d-3;
      echo '<table class="settingsTable">';
      echo '<tr style="text-align:center;"><td>Time Offset: ' . getTimeOffset() . '</td><td>Sunrise: ' . getSunrise(SUNFUNCS_RET_STRING) . '</td><td>Sunset: ' . getSunset(SUNFUNCS_RET_STRING) . '</td><td>Current: ' . getCurrentLocalTime(false) . "</td><td>Period: $period </td></tr></table>";
      
      $columns = explode(';', LBL_COLUMNS);
      echo '<table class="settingsTable">';
      $h = -1;
      echo '<tr style="font-weight:bold;text-align: center;">';
      foreach($columns as $column) {
            echo '<td>' . $column . '</td>';
      }
      echo '</h3></tr>';
      $times = $pars[SCHEDULE_TIMES];
      $cmdsOn = $pars[SCHEDULE_COMMANDSON];
      $cmdsOff = $pars[SCHEDULE_COMMANDSOFF];
      $modes = $pars[SCHEDULE_MODES];
      $row = 0;
      for($row = 0; $row < (count($times) + 4); $row++) {
         if ($row == 2) {
            $class = 'day';
         } else if ($row < 4) {
            $class = 'sun';
         } else {
            $class = 'fixed';
         }
         echo "<tr class='$class'>";
         if ($row == $d) {
            echo '<td style = "background-color: LightGreen;">';
         } else {
            echo '<td>';
         }
         if($row < 4) {
            echo $periods[$row] . '&nbsp;&nbsp;</td>';
         } else {
            echo "<input type='text' autocomplete='off' size='10' name='" . SCHEDULE_TIMES . "[]' value='" . htmlspecialchars($times[$row -4], ENT_QUOTES) . "'/> &nbsp;&nbsp;</td>";
         }
         echo "<td><input type='text' autocomplete='off' size='24' name='" . SCHEDULE_COMMANDSON . "[]' value='" . htmlspecialchars($cmdsOn[$row], ENT_QUOTES) . "'/>&nbsp;&nbsp;</td>";
         echo "<td><input type='text' autocomplete='off' size='24' name='" . SCHEDULE_COMMANDSOFF . "[]' value='" . htmlspecialchars($cmdsOff[$row], ENT_QUOTES) . "'/>&nbsp;&nbsp;</td>";
         echo "<td><input type='text' autocomplete='off' size='24' name='" . SCHEDULE_MODES . "[]' value='" . htmlspecialchars($modes[$row], ENT_QUOTES) . "'/>&nbsp;&nbsp;</td>";
         echo '</tr>';
      }
      echo '</table>';
   }

   function displayLog() {
      global $logFile;
      if (file_exists($logFile)) {
         $logData = file_get_contents($logFile);
         echo str_replace(PHP_EOL, '<BR>', $logData);
      } else {
         echo "No log data found";
      }
   }

   function mainHTML() {
      global $schedulePID, $schedulePars, $debugString, $showLog;
      echo '<!DOCTYPE html>';
      echo '<html>';
         echo '<head>';
            echo '<meta name="viewport" content="width=550, initial-scale=1">';
            echo '<title>RPi Cam Download</title>';
            echo '<link rel="stylesheet" href="css/style_minified.css" />';
            echo '<link rel="stylesheet" href="css/extrastyle.css" />';
            echo '<script src="js/style_minified.js"></script>';
            echo '<script src="js/script.js"></script>';
         echo '</head>';
         echo '<body onload="schedule_rows()">';
            echo '<div class="navbar navbar-inverse navbar-fixed-top" role="navigation">';
               echo '<div class="container">';
                  echo '<div class="navbar-header">';
                     if ($showLog) {
                        echo '<a class="navbar-brand" href="schedule.php">';
                     } else {
                        echo '<a class="navbar-brand" href="index.php">';
                     }
                     echo '<span class="glyphicon glyphicon-chevron-left"></span>Back - ' . CAM_STRING . '</a>';
                  echo '</div>';
               echo '</div>';
            echo '</div>';
          
            echo '<div class="container-fluid">';
               echo '<form action="schedule.php" method="POST">';
                  if ($debugString) echo $debugString . "<br>";
                  if ($showLog) {
                     echo "&nbsp&nbsp;<button class='btn btn-primary' type='submit' name='action' value='downloadlog'>" . BTN_DOWNLOADLOG . "</button>";
                     echo "&nbsp&nbsp;<button class='btn btn-primary' type='submit' name='action' value='clearlog'>" . BTN_CLEARLOG . "</button><br><br>";
                     displayLog();
                  } else {
                     echo '<div class="container-fluid text-center">';
                     echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='save'>" . BTN_SAVE . "</button>";
                     echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='backup'>" . BTN_BACKUP . "</button>";
                     echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='restore'>" . BTN_RESTORE . "</button>";
                     echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='showlog'>" . BTN_SHOWLOG . "</button>";
                     echo '&nbsp;&nbsp;&nbsp;&nbsp;';
                     if ($schedulePID != 0) {
                        echo "<button class='btn btn-danger' type='submit' name='action' value='stop'>" . BTN_STOP . "</button>";
                     } else {
                        echo "<button class='btn btn-danger' type='submit' name='action' value='start'>" . BTN_START . "</button>";
                     }
                     echo "<br></div>";
                     showScheduleSettings($schedulePars);
                  }
               echo '</form>';
            echo '</div>';
            cmdHelp();
         echo '</body>';
      echo '</html>';
   }

function cmdHelp() {
   echo "<div class='container-fluid text-center'>";
   echo "<div class='panel-group' id='accordion'>";
     echo "<div class='panel panel-default'>";
       echo "<div class='panel-heading'>";
         echo "<h2 class='panel-title'>";
           echo "<a data-toggle='collapse' data-parent='#accordion' href='#collapseOne'>Command reference</a>";
         echo "</h2>";
       echo "</div>";
       echo "<div id='collapseOne' class='panel-collapse collapse'>";
         echo "<div class='panel-body'>";
           echo "<table class='settingsTable'>";
             echo "<tr><th>Command</th><th>Parameters</th><th>Description</th></tr>";
             echo "<tr><td>md</td><td>0/1</td><td>0/1 stop/start motion detection</td></tr>";
             echo "<tr><td>ca</td><td>0/1</td><td>0/1 stop/start video capture</td></tr>";
             echo "<tr><td>im</td><td></td><td>capture image</td></tr>";
             echo "<tr><td>tl</td><td>0/1</td><td>start/stop timelapse</td></tr>";
             echo "<tr><td>tv</td><td>number</td><td>set timelapse interval between images n * 1/10 seconds.</td></tr>";
             echo "<tr><td>an</td><td>text</td><td>set annotation</td></tr>";
             echo "<tr><td>ab</td><td>0/1</td><td>annotation background</td></tr>";
             echo "<tr><td>px</td><td>AAAA BBBB CC DD EEEE FFFF</td><td>set video+img resolution  video = AxB px, C fps, boxed with D fps, image = ExF px)</td></tr>";
             echo "<tr><td>av</td><td>2/3</td><td>set annotation version</td></tr>";
             echo "<tr><td>as</td><td>number</td><td>set text size (v3 only)  0-99</td></tr>";
             echo "<tr><td>at</td><td>E YYY UUU VVV</td><td>set custom text colour (v3 only)</td></tr>";
             echo "<tr><td>ac</td><td>E YYY UUU VVV</td><td>set custom background colour (v3 only)</td></tr>";
             echo "<tr><td>sh</td><td>number</td><td>set sharpness (range: [-100;100]; default: 0)</td></tr>";
             echo "<tr><td>co</td><td>number</td><td>set contrast (range: [-100;100]; default: 0)</td></tr>";
             echo "<tr><td>br</td><td>number</td><td>set brightness (range: [0;100]; default: 50)</td></tr>";
             echo "<tr><td>sa</td><td>number</td><td>set saturation (range: [-100;100]; default: 0)</td></tr>";
             echo "<tr><td>is</td><td>number</td><td>set ISO (range: [100;800]; default: 0=auto)</td></tr>";
             echo "<tr><td>vs</td><td>number</td><td>0/1 turn off/on video stabilisation</td></tr>";
             echo "<tr><td>ec</td><td>number</td><td>set exposure compensation (range: [-10;10]; default: 0)</td></tr>";
             echo "<tr><td>em</td><td>keyword</td><td>set exposure mode (range: [off/auto/night/nightpreview/backlight/spotlight/sports/snow/beach/verylong/fixedfps/antishake/fireworks]; default: auto)</td></tr>";
             echo "<tr><td>wb</td><td>keyword</td><td>set white balance (range: [off/auto/sun/cloudy/shade/tungsten/fluorescent/incandescent/flash/horizon]; default: auto)</td></tr>";
             echo "<tr><td>mm</td><td>keyword</td><td>set metering mode (range: [average/spot/backlit/matrix]; default: average)</td></tr>";
             echo "<tr><td>ie</td><td>keyword</td><td>set image effect (range: [none/negative/solarise/posterize/whiteboard/blackboard/sketch/denoise/emboss/oilpaint/hatch/gpen/pastel/watercolour/film/blur/saturation/colourswap/washedout/posterise/colourpoint/colourbalance/cartoon]; default: none)</td></tr>";
             echo "<tr><td>ce</td><td>A BB CC</td><td>set colour effect (A BB CC; A=enable/disable, effect = B:C)</td></tr>";
             echo "<tr><td>ro</td><td>number</td><td>set rotation (range: [0/90/180/270]; default: 0)</td></tr>";
             echo "<tr><td>fl</td><td>number</td><td>set flip (range: [0;3]; default: 0)</td></tr>";
             echo "<tr><td>ri</td><td>AAAAA BBBBB CCCCC DDDDD</td><td>set sensor region (x=A, y=B, w=C, h=D)</td></tr>";
             echo "<tr><td>qu</td><td>number</td><td>set output image quality (range: [0;100]; default: 85)</td></tr>";
             echo "<tr><td>bi</td><td>number</td><td>set output video bitrate (range: [0;25000000]; default: 17000000)</td></tr>";
             echo "<tr><td>bo</td><td>number</td><td>set MP4Box mode (0=off, 1=inline, 2=background";
             echo "<tr><td>rl</td><td>0/1</td><td>0/1 disable / enable raw layer</td></tr>";
             echo "<tr><td>rs</td><td>1</td><td>Reset user config to default</td></tr>";
             echo "<tr><td>ru</td><td>0/1</td><td>0/1 halt/restart RaspiMJPEG and release camera</td></tr>";
           echo "</table>";
         echo "</div>";
       echo "</div>";
     echo "</div>";
   echo "</div>";
   echo "</div>";
}
 
   function sendReset() {
      global $schedulePars, $logFile;
      writeLog("Send Schedule reset");
      $fifo = fopen($schedulePars[SCHEDULE_FIFOIN], "w");
      fwrite($fifo, SCHEDULE_RESET);
      fclose($fifo);
      sleep(1);
   }
   
   function sendCmds($cmdString) {
      global $schedulePars, $logFile;

      $cmds = explode(';', $cmdString);
      foreach ($cmds as $cmd) {
         if ($cmd != "") {
            writeLog("Send $cmd");
            $fifo = fopen($schedulePars[SCHEDULE_FIFOOUT], "w");
            fwrite($fifo, $cmd);
            fclose($fifo);
            sleep(2);
         }
      }
   }
   
   function getTimeOffset() {
      global $schedulePars;
      if (is_numeric($schedulePars[SCHEDULE_GMTOFFSET])) {
         $offset = $schedulePars[SCHEDULE_GMTOFFSET];
      } else {
         date_default_timezone_set($schedulePars[SCHEDULE_GMTOFFSET]);
         $offset = date_offset_get(new DateTime("now")) / 3600; 
      }
      return $offset;
   }
   
   function getCurrentLocalTime($Minutes) {
      $localTime = strftime("%H:%M");
      if ($Minutes) {
         $localTime = substr($localTime,0,2) * 60 + substr($localTime,3,2);
      }
      return $localTime;
   }
   
   function getSunrise($format) {
      global $schedulePars;
      return date_sunrise(time(), $format, $schedulePars[SCHEDULE_LATITUDE], $schedulePars[SCHEDULE_LONGTITUDE], SCHEDULE_ZENITH, getTimeOffset());
   }
   
   function getSunset($format) {
      global $schedulePars; 
      return date_sunset(time(), $format, $schedulePars[SCHEDULE_LATITUDE], $schedulePars[SCHEDULE_LONGTITUDE], SCHEDULE_ZENITH, getTimeOffset());
   }

   function findFixedTimePeriod($cMins) {
      global $schedulePars, $logFile;
      $times = $schedulePars[SCHEDULE_TIMES];
      $maxLessI = count($times) - 1;$maxLessV = -1;
      for ($i=0; $i < count($times); $i++) {
         $fMins = $times[$i];
         $j = strpos($fMins, ':');
         $fMins = substr($fMins, 0, $j) * 60 + substr($fMins, $j+1);
         writeLog("ix $i c $cMins f $fMins");
         if ($fMins < $cMins) {
            if ($fMins > $maxLessV) {
               $maxLessV = $fMins;
               $maxLessI = $i;
            }
         }
      }
      return $maxLessI + 4;
   }
   
   //Return period of day 0=Night,1=Dawn,2=Day,3=Dusk
   function dayPeriod() {
      global $schedulePars, $logFile;
      $t = getCurrentLocalTime(true);
      switch($schedulePars[SCHEDULE_DAYMODE]) {
         case 0:
            $sr = 60 * getSunrise(SUNFUNCS_RET_DOUBLE);
            $ss = 60 * getSunset(SUNFUNCS_RET_DOUBLE);
            if ($t < ($sr + $schedulePars[SCHEDULE_DAWNSTARTMINUTES])) {
               $period = 0;
            } else if ($t < ($sr + $schedulePars[SCHEDULE_DAYSTARTMINUTES])) {
               $period = 1;
            } else if ($t > ($ss + $schedulePars[SCHEDULE_DUSKENDMINUTES])) {
               $period = 0;
            } else if ($t > ($ss + $schedulePars[SCHEDULE_DAYENDMINUTES])) {
               $period = 3;
            } else {
               $period = 2;
            }
            break;
         case 1:
            $period = 2;
            break;
         case 2:
            $times = $schedulePars[SCHEDULE_TIMES];
            $period = count($times) - 1;$maxLessV = -1;
            for ($i=0; $i < count($times); $i++) {
               $fMins = $times[$i];
               $j = strpos($fMins, ':');
               if ($j > 0) {
                  $fMins = substr($fMins, 0, $j) * 60 + substr($fMins, $j+1);
                  if ($fMins <= $t) {
                     if ($fMins > $maxLessV) {
                        $maxLessV = $fMins;
                        $period = $i;
                     }
                  }
               }
            }
            $period += 4;
            break;
      }
      return $period;
   }
   
   function openPipe($pipeName) {
      global $logFile;
      if (!file_exists($pipeName)) {
         writeLog("Making Pipe to receive capture commands $pipeName");
         posix_mkfifo($pipeName,0666);
         chmod($pipeName, 0666);
      } else {
         writeLog("Capture Pipe already exists $pipeName");
      }
      $pipe = fopen($pipeName,'r+');
      stream_set_blocking($pipe,false);
      return $pipe;
   }
   
   function checkMotion($pipe) {
      try {
         $ret = fread($pipe, 1);
      } catch (Exception $e) {
         $ret = "";
      }
      return $ret;
   }

   function purgeFiles($videoHours, $imageHours, $lapseHours) {
      global $logFile;
      if ($videoHours > 0 || $imageHours > 0) {
         $files = scandir(MEDIA_PATH);
         $purgeCount = 0;
         $currentHours = time() / 3600;
         foreach($files as $file) {
            if(($file != '.') && ($file != '..') && (substr($file, -7) == '.th.jpg')) {
               $fType = substr($file,-12, 1);
               $purgeHours = 0;
               switch ($fType) {
                  case 'i': $purgeHours = $imageHours;
                     break;
                  case 't': $purgeHours = $lapseHours;
                     break;
                  case 'v': $purgeHours = $videoHours;
                     break;
               }
               if ($purgeHours > 0) {
                  $fModHours = filemtime(MEDIA_PATH . "/$file") / 3600;
                  if ($fModHours > 0 && ($currentHours - $fModHours) > $purgeHours) {
                     deleteFile($file);
                     $purgeCount++;
                  }
               }
            } 
         }
         writeLog("Purged $purgeCount Files");
      }
   }

   function mainCLI() {
      global $schedulePars, $logFile;
      writeLog("RaspiCam support started");
      $captureCount = 0;
      $pipeIn = openPipe($schedulePars[SCHEDULE_FIFOIN]);
      $lastDayPeriod = -1;
      $cmdPeriod = -1;
      $lastOnCommand = -1;
      $timeout = 0;
      $timeoutMax = 0; //Loop test will terminate after this (seconds) (used in test), set to 0 forever
      while($timeoutMax == 0 || $timeout < $timeoutMax) {
         $logFile = BASE_DIR . '/' . $schedulePars[SCHEDULE_LOGFILE];
         writeLog("Scheduler loop is started");
         $pollTime = $schedulePars[SCHEDULE_CMDPOLL];
         $modeTimeInterval = $schedulePars[SCHEDULE_MODEPOLL];
         $manageTimer = 0;
         $modetimeCount = 0;

         while($timeoutMax == 0 || $timeout < $timeoutMax) {
            usleep($pollTime * 1000000);
            //Check for incoming motion capture requests
            $cmd = checkMotion($pipeIn);
            if ($cmd == SCHEDULE_STOP) {
               if ($lastOnCommand >= 0) {
                  writeLog('Stop capture requested');
                  $send = $schedulePars[SCHEDULE_COMMANDSOFF][$lastOnCommand];
                  if ($send) {
                     sendCmds($send);
                     $lastOnCommand = -1;
                  }
               } else {
                  writeLog('Stop capture request ignored, already stopped');
                  $captureCount = 0;
               }
            } else if ($cmd == SCHEDULE_START) {
               if ($lastOnCommand < 0 && $lastDayPeriod >= 0) {
                  writeLog('Start capture requested');
                  $send = $schedulePars[SCHEDULE_COMMANDSON][$lastDayPeriod];
                  if ($send) {
                     sendCmds($send);
                     $lastOnCommand = $lastDayPeriod;
                  }
               } else {
                  writeLog('Start capture request ignored, already started');
               }
            } else if ($cmd == SCHEDULE_RESET) {
               writeLog("Reload parameters command requested");
               $schedulePars = loadPars(BASE_DIR . '/' . SCHEDULE_CONFIG);
               //start outer loop
               break;
            } else if ($cmd !="") {
               writeLog("Ignore FIFO char $cmd");
            }

            //Action period time change checks at TIME_CHECK intervals
            $modetimeCount -= $pollTime;
            if ($modetimeCount < 0) {
               $modetimeCount =  $modeTimeInterval;
               $timeout += $modeTimeInterval;
               if ($lastOnCommand < 0) {
                  //No capture in progress, Check if day period changing
                  $captureCount = 0;
                  $newDayPeriod = dayPeriod();
                  if ($newDayPeriod != $lastDayPeriod) {
                     writeLog("New period detected $newDayPeriod");
                     sendCmds($schedulePars[SCHEDULE_MODES][$newDayPeriod]);
                     $lastDayPeriod = $newDayPeriod;
                  }
               } else {
                  //Capture in progress, Check for maximum
                  if ($schedulePars[SCHEDULE_MAXCAPTURE] > 0) {
                     $captureCount += $modeTimeInterval;
                     if ($captureCount > $schedulePars[SCHEDULE_MAXCAPTURE]) {
                        writeLog("Maximum Capture reached. Sending off");
                        sendCmds($schedulePars[SCHEDULE_COMMANDSOFF][$lastOnCommand]);
                        $lastOnCommand = -1;
                        $captureCount = 0;
                     }
                  }
               }
               $manageTimer -= $modeTimeInterval;
               if ($manageTimer < 0) {
                  // Run management tasks
                  writeLog('Scheduled management tasks');
                  $manageTimer = $schedulePars[SCHEDULE_MANAGEMENTINTERVAL];
                  purgeFiles($schedulePars[SCHEDULE_PURGEVIDEOHOURS], $schedulePars[SCHEDULE_PURGEIMAGEHOURS], $schedulePars[SCHEDULE_PURGELAPSEHOURS]);
                  $cmd = $schedulePars[SCHEDULE_MANAGEMENTCOMMAND];
                  if ($cmd != '') {
                     writeLog("exec: $cmd");
                     exec($cmd);
                  }
               }
            }
         }
      }
   }
   
   if (!$cliCall) {
      mainHTML();
   } else {
      mainCLI();
   }
?>
