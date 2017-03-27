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
   define('LBL_PERIODS', 'AllDay;Night;Dawn;Day;Dusk');
   define('LBL_COLUMNS', 'Period;Days Su-Sa;Motion Start;Motion Stop;Period Start');
   define('LBL_PARAMETERS', 'Parameter;Value');
   define('LBL_DAYMODES', 'Sun based;All Day;Fixed Times');
   define('LBL_PURGESPACEMODES', 'Off;Min Space %;Max Usage %;Min Space GB;Max Usage GB');
   define('LBL_DAWN', 'Dawn');
   define('LBL_DAY', 'Day');
   define('LBL_DUSK', 'Dusk');

   define('SCHEDULE_CONFIG', 'schedule.json');
   define('SCHEDULE_CONFIGBACKUP', 'scheduleBackup.json');
 
   define('SCHEDULE_START', '1');
   define('SCHEDULE_STOP', '0');
   define('SCHEDULE_RESET', '9');
   
   define('SCHEDULE_TIMES_MAX', '12');
   
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
   define('SCHEDULE_PURGESPACEMODE', 'PurgeSpace_ModeEx');
   define('SCHEDULE_PURGESPACELEVEL', 'PurgeSpace_Level');
   define('SCHEDULE_AUTOCAPTUREINTERVAL', 'AutoCapture_Interval');
   define('SCHEDULE_AUTOCAMERAINTERVAL', 'AutoCamera_Interval');
   define('SCHEDULE_COMMANDSON', 'Commands_On');
   define('SCHEDULE_COMMANDSOFF', 'Commands_Off');
   define('SCHEDULE_MODES', 'Modes');
   define('SCHEDULE_TIMES', 'Times');
   define('SCHEDULE_DAYS', 'Days');
   
   $debugString = "";
   $schedulePars = array();
   $schedulePars = loadPars(BASE_DIR . '/' . SCHEDULE_CONFIG);
   
   $cliCall = isCli();
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
            if (file_exists(getLogFile())) {
               header("Content-Type: text/plain");
               header("Content-Disposition: attachment; filename=\"" . date('Ymd-His-') . LOGFILE_SCHEDULE . "\"");
               readfile(getLogFile());
               return;
            }
         case 'clearlog':
            if (file_exists(getLogFile())) {
               unlink(getLogFile());
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
      exec("ps -ef", $pids);
      $pidId = 0;
      foreach ($pids as $pid) {
         if (strpos($pid, 'schedule.php') !== false) {
            $fields = preg_split('#\s+#', $pid, null, PREG_SPLIT_NO_EMPTY);
            if (is_numeric($fields[1])) {
               $pidId = $fields[1];
            }
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
            //Backwards compatibility fixes go here
            if (array_key_exists(SCHEDULE_ALLDAY,$input)) $pars[SCHEDULE_DAYMODE] = '1';
            //Duplicate old Day to First AllDay
            if (count($pars[SCHEDULE_COMMANDSON]) < 11) {
               array_unshift($pars[SCHEDULE_COMMANDSON], $pars[SCHEDULE_COMMANDSON][2]);
               array_unshift($pars[SCHEDULE_COMMANDSOFF], $pars[SCHEDULE_COMMANDSOFF][2]);
               array_unshift($pars[SCHEDULE_MODES], $pars[SCHEDULE_MODES][2]);
            }
         } catch (Exception $e) {
         }
      }
	  // Add in any extra SCHEDULE_TIMES and SCHEDULE_DAYS settings up to maximum count
	  for($i = count($pars[SCHEDULE_TIMES]); $i < SCHEDULE_TIMES_MAX; $i++) {
		  $pars[SCHEDULE_TIMES][$i] = sprintf("%02d", $i+9).":00";
	  }
	  for($i = count($pars[SCHEDULE_DAYS]); $i < (SCHEDULE_TIMES_MAX + 5); $i++) {
		  $pars[SCHEDULE_DAYS][$i] = array(0,1,2,3,4,5,6);
	  }
      return $pars;
   }

   function initPars() {
      $pars = array(
         SCHEDULE_FIFOIN => BASE_DIR.'/FIFO1',
         SCHEDULE_FIFOOUT => BASE_DIR.'/FIFO',
         SCHEDULE_CMDPOLL => '0.03',
         SCHEDULE_MODEPOLL => '10',
         SCHEDULE_MANAGEMENTINTERVAL => '3600',
         SCHEDULE_MANAGEMENTCOMMAND => '',
         SCHEDULE_PURGEVIDEOHOURS => '0',
         SCHEDULE_PURGEIMAGEHOURS => '0',
         SCHEDULE_PURGELAPSEHOURS => '0',
         SCHEDULE_GMTOFFSET => '0',
         SCHEDULE_PURGESPACEMODE => '0',
         SCHEDULE_PURGESPACELEVEL => '10',
         SCHEDULE_DAWNSTARTMINUTES => '-180',
         SCHEDULE_DAYSTARTMINUTES => '0',
         SCHEDULE_DAYENDMINUTES => '0',
         SCHEDULE_DUSKENDMINUTES => '180',
         SCHEDULE_LATITUDE => '52.00',
         SCHEDULE_LONGTITUDE => '0.00',
         SCHEDULE_MAXCAPTURE => '0',
         SCHEDULE_DAYMODE => '1',
         SCHEDULE_AUTOCAPTUREINTERVAL => '0',
         SCHEDULE_AUTOCAMERAINTERVAL => '0',
//         SCHEDULE_TIMES => array("09:00","10:00","11:00","12:00","13:00","14:00","15:00","16:00","17:00","18:00"),
         SCHEDULE_TIMES => array("09:00"),
         SCHEDULE_DAYS => array(array(0,1,2,3,4,5,6)),
//         SCHEDULE_DAYS => array(array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6),array(0,1,2,3,4,5,6)),
         SCHEDULE_COMMANDSON => array("ca 1","","","ca 1","","","","","","",""),
         SCHEDULE_COMMANDSOFF => array("ca 0","","","ca 0","","","","","","",""),
         SCHEDULE_MODES => array("","em night","md 1;em night","em auto","md 0;em night","","","","","","")
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
            switch ($mKey) {
               case SCHEDULE_DAYMODE:
                  $options = explode(';', LBL_DAYMODES);
                  echo "<td>$mKey&nbsp;&nbsp;</td><td>Select Mode&nbsp;<select id='$mKey' name='$mKey'" .' onclick="schedule_rows();">';
                  for($i = 0; $i < count($options); $i++) {
                     if ($i == $mValue) $selected = ' selected'; else $selected ='';
                     $option = $options[$i];
                     echo "<option value='$i'$selected>$option</option>";
                  }
                  echo '</select></td>';
                  break;
               case SCHEDULE_PURGESPACEMODE:
                  $options = explode(';', LBL_PURGESPACEMODES);
                  echo "<td>$mKey&nbsp;&nbsp;</td><td>Select Mode&nbsp;<select id='$mKey' name='$mKey'>";
                  for($i = 0; $i < count($options); $i++) {
                     if ($i == $mValue) $selected = ' selected'; else $selected ='';
                     $option = $options[$i];
                     echo "<option value='$i'$selected>$option</option>";
                  }
                  echo '</select></td>';
                  break;
               default:
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
      if ($d < 5) $period = $periods[$d]; else $period = $d-4;
      echo '<table class="settingsTable">';
      echo '<tr style="text-align:center;"><td>Time Offset: ' . getTimeOffset() . '</td><td>Sunrise: ' . getSunrise(SUNFUNCS_RET_STRING) . '</td><td>Sunset: ' . getSunset(SUNFUNCS_RET_STRING) . '</td><td>Current: ' . getCurrentLocalTime(false) . "</td><td>Period: $period </td></tr></table>";
      
      $columns = explode(';', LBL_COLUMNS);
      echo '<table class="settingsTable">';
      $h = -1;
      echo '<tr style="font-weight:bold;text-align: center;">';
      foreach($columns as $column) {
            echo '<td>' . $column . '</td>';
      }
      echo '</tr>';
      $times = $pars[SCHEDULE_TIMES];
	  $days = $pars[SCHEDULE_DAYS];
      $cmdsOn = $pars[SCHEDULE_COMMANDSON];
      $cmdsOff = $pars[SCHEDULE_COMMANDSOFF];
      $modes = $pars[SCHEDULE_MODES];
      $row = 0;
      for($row = 0; $row < (count($times) + 5); $row++) {
         if ($row == 0) {
            $class = 'day';
         } else if ($row < 5) {
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
         if($row < 5) {
            echo $periods[$row] . '&nbsp;&nbsp;</td>';
         } else {
            echo "<input type='text' autocomplete='off' size='10' name='" . SCHEDULE_TIMES . "[]' value='" . htmlspecialchars($times[$row -5], ENT_QUOTES) . "'/> &nbsp;&nbsp;</td>";
         }
		 echo '<td>';
		 for($dy = 0;$dy <7;$dy++) {
			echo "<input type='checkbox' name='" . SCHEDULE_DAYS . "[$row][]' value=$dy" . (in_array($dy, $days[$row]) ? " checked" : "") . "/>"; 
		 }
		 echo '</td>';
         echo "<td><input type='text' autocomplete='off' size='24' name='" . SCHEDULE_COMMANDSON . "[]' value='" . htmlspecialchars($cmdsOn[$row], ENT_QUOTES) . "'/>&nbsp;&nbsp;</td>";
         echo "<td><input type='text' autocomplete='off' size='24' name='" . SCHEDULE_COMMANDSOFF . "[]' value='" . htmlspecialchars($cmdsOff[$row], ENT_QUOTES) . "'/>&nbsp;&nbsp;</td>";
         echo "<td><input type='text' autocomplete='off' size='24' name='" . SCHEDULE_MODES . "[]' value='" . htmlspecialchars($modes[$row], ENT_QUOTES) . "'/>&nbsp;&nbsp;</td>";
         echo '</tr>';
      }
      echo '</table>';
   }

   function displayLog() {
      if (file_exists(getLogFile())) {
         $logData = file_get_contents(getLogFile());
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
            echo '<title>' . CAM_STRING . ' Schedule</title>';
            echo '<link rel="stylesheet" href="css/style_minified.css" />';
            echo '<link rel="stylesheet" href="' . getStyle() . '" />';
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
                        echo '<a class="navbar-brand" href="' . ROOT_PHP . '">';
                     }
                     echo '<span class="glyphicon glyphicon-chevron-left"></span>Back - ' . CAM_STRING . '</a>';
                  echo '</div>';
               echo '</div>';
            echo '</div>';
          
            echo '<div class="container-fluid">';
               echo '<form action="schedule.php" method="POST">';
                  if ($debugString) echo $debugString . "<br>";
                  if ($showLog) {
                     displayLog();
                  } else {
                     echo '<div class="container-fluid text-center">';
                     echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='save'>" . BTN_SAVE . "</button>";
                     echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='backup'>" . BTN_BACKUP . "</button>";
                     echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='restore'>" . BTN_RESTORE . "</button>";
                     echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='showlog'>" . BTN_SHOWLOG . "</button>";
                     echo "&nbsp&nbsp;<button class='btn btn-primary' type='submit' name='action' value='downloadlog'>" . BTN_DOWNLOADLOG . "</button>";
                     echo "&nbsp&nbsp;<button class='btn btn-primary' type='submit' name='action' value='clearlog'>" . BTN_CLEARLOG . "</button>";
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
             echo "<tr><td>ca c [t]</td><td>0/1</td><td>c=0/1 stop/start video capture; t=capture secs if present</td></tr>";
             echo "<tr><td>im</td><td></td><td>capture image</td></tr>";
             echo "<tr><td>tl</td><td>0/1</td><td>stop/start timelapse</td></tr>";
             echo "<tr><td>tv</td><td>number</td><td>set timelapse interval between images n * 1/10 seconds.</td></tr>";
             echo "<tr><td>vi</td><td>number</td><td>set video split interval in seconds. 0=Off</td></tr>";
             echo "<tr><td>an</td><td>text</td><td>set annotation</td></tr>";
             echo "<tr><td>ab</td><td>0/1</td><td>annotation background</td></tr>";
             echo "<tr><td>px</td><td>AAAA BBBB CC DD EEEE FFFF</td><td>set video+img resolution  video = AxB px, C fps, boxed with D fps, image = ExF px)</td></tr>";
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
             echo "<tr><td>ag</td><td>RRRR BBBB</td><td>set white balance off red_gain blue gain (100 = 1.0; default: 150)</td></tr>";
             echo "<tr><td>mm</td><td>keyword</td><td>set metering mode (range: [average/spot/backlit/matrix]; default: average)</td></tr>";
             echo "<tr><td>ie</td><td>keyword</td><td>set image effect (range: [none/negative/solarise/posterize/whiteboard/blackboard/sketch/denoise/emboss/oilpaint/hatch/gpen/pastel/watercolour/film/blur/saturation/colourswap/washedout/posterise/colourpoint/colourbalance/cartoon]; default: none)</td></tr>";
             echo "<tr><td>ce</td><td>A BB CC</td><td>set colour effect (A BB CC; A=enable/disable, effect = B:C)</td></tr>";
             echo "<tr><td>ro</td><td>number</td><td>set rotation (range: [0/90/180/270]; default: 0)</td></tr>";
             echo "<tr><td>fl</td><td>number</td><td>set flip (range: [0;3]; default: 0)</td></tr>";
             echo "<tr><td>ri</td><td>AAAAA BBBBB CCCCC DDDDD</td><td>set sensor region (x=A, y=B, w=C, h=D)</td></tr>";
             echo "<tr><td>qu</td><td>number</td><td>set output image quality (range: [0;100]; default: 85)</td></tr>";
             echo "<tr><td>pv</td><td>QQ WWW DD</td><td>set preview quality (0-100) default 25, Width (128-1024) default 512, Divider (1-16) default 1</td></tr>";
             echo "<tr><td>bu</td><td>number</td><td>set pre-trigger video buffer in mSec (approx)</td></tr>";
             echo "<tr><td>bi</td><td>number</td><td>set output video bitrate (range: [0;25000000]; default: 17000000)</td></tr>";
             echo "<tr><td>bo</td><td>number</td><td>set MP4Box mode (0=off, 1=inline, 2=background";
             echo "<tr><td>rl</td><td>0/1</td><td>0/1 disable / enable raw layer</td></tr>";
             echo "<tr><td>rs</td><td>1</td><td>Reset user config to default</td></tr>";
             echo "<tr><td>ru</td><td>0/1</td><td>0/1 halt/restart RaspiMJPEG and release camera</td></tr>";
             echo "<tr><td>sc</td><td>1</td><td>Rescan for video and image indexes</td></tr>";
             echo "<tr><td>sy</td><td>macro</td><td>Execute macro</td></tr>";
             echo "<tr><td>vp</td><td>0/1</td><td>Disable/Enable vector preview</td></tr>";
             echo "<tr><td>mn</td><td>number</td><td>Set motion_noise</td></tr>";
             echo "<tr><td>mt</td><td>number</td><td>Set motion_threshold</td></tr>";
             echo "<tr><td>mi</td><td>filename</td><td>Set motion_image</td></tr>";
             echo "<tr><td>mb</td><td>number</td><td>Set motion_startframes</td></tr>";
             echo "<tr><td>me</td><td>number</td><td>Set motion_stopframes</td></tr>";
             echo "<tr><td>cn</td><td>1/2</td><td>Select camera (Compute model only)</td></tr>";
             echo "<tr><td>st</td><td>0/1</td><td>Off/On Camera statistics</td></tr>";
             echo "<tr><td>ls</td><td>number</td><td>Set Max log size. 0 disable logging</td></tr>";
           echo "</table>";
         echo "</div>";
       echo "</div>";
     echo "</div>";
   echo "</div>";
   echo "</div>";
}
 
   function sendReset() {
      global $schedulePars;
      writeLog("Send Schedule reset");
      $fifo = fopen($schedulePars[SCHEDULE_FIFOIN], "w");
      fwrite($fifo, SCHEDULE_RESET);
      fclose($fifo);
      sleep(1);
   }
   
   function sendCmds($cmdString, $period = false) {
      global $schedulePars;
	  if($period === false || isDayActive($period))
      $cmds = explode(';', $cmdString);
	  foreach ($cmds as $cmd) {
		if ($cmd != "") {
			writeLog("Send $cmd");
			$fifo = fopen($schedulePars[SCHEDULE_FIFOOUT], "w");
			fwrite($fifo, $cmd . "\n");
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
      global $schedulePars;
      $times = $schedulePars[SCHEDULE_TIMES];
      $period = count($times) - 1;$maxLessV = -1;
      for ($i=0; $i < count($times); $i++) {
         $fMins = $times[$i];
         $j = strpos($fMins, ':');
         $fMins = substr($fMins, 0, $j) * 60 + substr($fMins, $j+1);
         if ($fMins < $cMins) {
            if ($fMins > $maxLessV) {
              $maxLessV = $fMins;
              $period = $i;
            }
         }
      }
      return $period + 5;
   }
   
   function isDayActive($period) {
      global $schedulePars;
	  $days = $schedulePars[SCHEDULE_DAYS];
	  $day = strftime("%w");
	  return in_array($day,$days[$period]);
   }
   
   //Return period of day 0=Night,1=Dawn,2=Day,3=Dusk
   function dayPeriod() {
      global $schedulePars;
      $t = getCurrentLocalTime(true);
      switch($schedulePars[SCHEDULE_DAYMODE]) {
         case 0:
            $sr = 60 * getSunrise(SUNFUNCS_RET_DOUBLE);
            $ss = 60 * getSunset(SUNFUNCS_RET_DOUBLE);
            if ($t < ($sr + $schedulePars[SCHEDULE_DAWNSTARTMINUTES])) {
               $period = 1;
            } else if ($t < ($sr + $schedulePars[SCHEDULE_DAYSTARTMINUTES])) {
               $period = 2;
            } else if ($t > ($ss + $schedulePars[SCHEDULE_DUSKENDMINUTES])) {
               $period = 1;
            } else if ($t > ($ss + $schedulePars[SCHEDULE_DAYENDMINUTES])) {
               $period = 4;
            } else {
               $period = 3;
            }
            break;
         case 1:
            $period = 0;
            break;
         case 2:
			$period = findFixedTimePeriod($t);
            break;
      }
      return $period;
   }
   
   function openPipe($pipeName) {
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

   function purgeLog() {
	  $logSize = getLogSize();
      if (file_exists(getLogFile()) && $logSize > 0) {
	     $logLines = file(getLogFile());
		 $logCount = count($logLines);
		 if($logCount > $logSize) {
			 file_put_contents(getLogFile(), implode('', array_slice($logLines, -$logSize)));
		 }
	  }
   }

   function purgeFiles() {
      global $schedulePars;
      $videoHours = $schedulePars[SCHEDULE_PURGEVIDEOHOURS];
      $imageHours = $schedulePars[SCHEDULE_PURGEIMAGEHOURS];
      $lapseHours = $schedulePars[SCHEDULE_PURGELAPSEHOURS];
      $purgeCount = 0;
      if ($videoHours > 0 || $imageHours > 0 || $lapseHours > 0) {
         $files = scandir(BASE_DIR . '/' . MEDIA_PATH);
         $currentHours = time() / 3600;
         foreach($files as $file) {
            if(($file != '.') && ($file != '..') && isThumbnail($file)) {
               $fType = getFileType($file);
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
                  $fModHours = filemtime(BASE_DIR . '/' . MEDIA_PATH . "/$file") / 3600;
                  if ($fModHours > 0 && ($currentHours - $fModHours) > $purgeHours) {
                     deleteFile($file);
                     $purgeCount++;
                  }
               }
            } 
         }
         
      }
      if ($schedulePars[SCHEDULE_PURGESPACEMODE] > 0) {
         $totalSize = disk_total_space(BASE_DIR . '/' . MEDIA_PATH) / 1024; //KB
         $level =  str_replace(array('%','G','B', 'g','b'), '', $schedulePars[SCHEDULE_PURGESPACELEVEL]);
         switch ($schedulePars[SCHEDULE_PURGESPACEMODE]) {
            case 1:
            case 2:
               $level = min(max($schedulePars[SCHEDULE_PURGESPACELEVEL], 3), 97) * $totalSize / 100;
               break;
            case 3:
            case 4:
               $level = $level * 1048576.0;
               break;
         }
         switch ($schedulePars[SCHEDULE_PURGESPACEMODE]) {
            case 1: //Free Space
            case 3:
               $currentAvailable = disk_free_space(BASE_DIR . '/' . MEDIA_PATH) / 1024; //KB
               //writeLog(" free space purge total $totalSize current: $currentAvailable target: $level");
               if ($currentAvailable < $level) {
                  $pFiles = getSortedFiles(false); //files in latest to earliest order
                  while($currentAvailable < $level && count($pFiles) > 0){
                     $currentAvailable += deleteFile(array_pop($pFiles));
                     $purgeCount++;
                  }
               }
               //writeLog("Finished. Current now: $currentAvailable");
               break;
            case 2: // Max usage
            case 4:
               $pFiles = getSortedFiles(false); //files in latest to earliest order
               //writeLog(" Max space purge max: $level");
               foreach ($pFiles as $pFile) {
                  $del = ($level <= 0);
                  $level -= deleteFile($pFile, $del);
                  if ($del) $purgeCount++;
               }
               break;
         }
      }
      if($purgeCount > 0){
        writeLog("Purged $purgeCount Files");
      }
   }

   function mainCLI() {
      global $schedulePars;
      writeLog("RaspiCam support started");
      $captureStart = 0;
      $pipeIn = openPipe($schedulePars[SCHEDULE_FIFOIN]);
      $timeout = 0;
      $timeoutMax = 0; //Loop test will terminate after this (seconds) (used in test), set to 0 forever
      while($timeoutMax == 0 || $timeout < $timeoutMax) {
         writeLog("Scheduler loop is started");
		 $lastOnCommand = -1;
         $lastDayPeriod = -1;
		 $lastDay = -1;
         $pollTime = $schedulePars[SCHEDULE_CMDPOLL];
         $slowPoll = 0;
         $managechecktime = time();
         $autocameratime =$managechecktime;
         $modechecktime = $managechecktime;
         if ($schedulePars[SCHEDULE_AUTOCAPTUREINTERVAL] > $schedulePars[SCHEDULE_MAXCAPTURE] ) {
            $autocapturetime = $managechecktime;
            $autocapture = 2;
         } else {
            $autocapturetime = 0;
            $autocapture = 0;
         }
         $lastStatusTime = filemtime(BASE_DIR . "/status_mjpeg.txt");
         while($timeoutMax == 0 || $timeout < $timeoutMax) {
            usleep($pollTime * 1000000);
            //Check for incoming motion capture requests
            $cmd = "";
            $cmd = checkMotion($pipeIn);
            if ($cmd == SCHEDULE_STOP && $autocapture == 0) {
               if ($lastOnCommand >= 0) {
                  writeLog('Stop capture requested');
                  $send = $schedulePars[SCHEDULE_COMMANDSOFF][$lastOnCommand];
                  if ($send) {
                     sendCmds($send, $lastDayPeriod);
                     $lastOnCommand = -1;
                  }
               } else {
                  writeLog('Stop capture request ignored, already stopped');
                  
               }
            } else if ($cmd == SCHEDULE_START || $autocapture == 1) {
               if ($lastDayPeriod >= 0) {
                  if ($autocapture == 1) {
                     $autocapture = 2;
                     writeLog('Start triggered by autocapture');
                  } else {
                     writeLog('Start capture requested from Pipe');
                  }
                  $send = $schedulePars[SCHEDULE_COMMANDSON][$lastDayPeriod];
                  if ($send) {
                     sendCmds($send, $lastDayPeriod);
                     $lastOnCommand = $lastDayPeriod;
                     $captureStart = time();
                  }
               } else {
                  writeLog('Start capture request ignored, day period not initialised yet');
               }
            } else if ($cmd == SCHEDULE_RESET) {
               writeLog("Reload parameters command requested");
               $schedulePars = loadPars(BASE_DIR . '/' . SCHEDULE_CONFIG);
               //start outer loop
               break;
            } else if ($cmd !="") {
               writeLog("Ignore FIFO char $cmd");
            }
            
            //slow Poll actions done every 10 fast loops times
            $slowPoll--;
            if ($slowPoll < 0) {
               $slowPoll = 10;
               $timenow = time();
               //Action period time change checks at MODE_POLL intervals
               if ($timenow > $modechecktime) {
                  //Set next period check time
                  $modechecktime = $timenow + $schedulePars[SCHEDULE_MODEPOLL];
                  if ($lastOnCommand < 0) {
                     //No capture in progress, Check if day period changing
                     $newDayPeriod = dayPeriod();
					 $newDay = strftime("%w");
                     if ($newDayPeriod != $lastDayPeriod || $newDay != $lastDay) {
                        writeLog("New period detected $newDayPeriod");
                        sendCmds($schedulePars[SCHEDULE_MODES][$newDayPeriod], $newDayPeriod);
                        $lastDayPeriod = $newDayPeriod;
						$lastDay = $newDay;
                     }
                  }
               }
               if ($lastOnCommand >= 0) {
                  //Capture in progress, Check for maximum
                  if ($schedulePars[SCHEDULE_MAXCAPTURE] > 0) {
                     if (($timenow - $captureStart) >= $schedulePars[SCHEDULE_MAXCAPTURE]) {
                        writeLog("Maximum Capture reached. Sending off command");
                        sendCmds($schedulePars[SCHEDULE_COMMANDSOFF][$lastOnCommand]);
                        $lastOnCommand = -1;
                        $autocapture = 0;
                     }
                  }
               }
               if ($timenow > $managechecktime) {
                  // Run management tasks
                  //Set next check time
                  $managechecktime = $timenow + $schedulePars[SCHEDULE_MANAGEMENTINTERVAL];
                  writeLog("Scheduled management tasks. Next at $managechecktime");
                  purgeFiles();
			      $cmd = $schedulePars[SCHEDULE_MANAGEMENTCOMMAND];
                  if ($cmd != '') {
                     writeLog("exec_macro: $cmd");
                     sendCmds("sy $cmd");
                  }
            	  purgeLog();
               }
               if ($autocapturetime > 0 && $timenow > $autocapturetime) {
                  // Request autocapture and set next interval
                  $autocapturetime = $timenow + $schedulePars[SCHEDULE_AUTOCAPTUREINTERVAL];
                  writeLog("Autocapture request.");
                  $autocapture = 1;
               }
               //Check for auto camera on/off based on status update timing (active browser)
               if (($schedulePars[SCHEDULE_AUTOCAMERAINTERVAL] > 0) && $timenow > $autocameratime) {
                  // 2 seconds between tests to allow time for commands to take effect
                  $autocameratime = $timenow + 2;
                  clearstatcache();
                  $modTime = filemtime(BASE_DIR . "/status_mjpeg.txt");
                  if (file_get_contents(BASE_DIR . "/status_mjpeg.txt") == 'halted') {
                     if ($modTime > $lastStatusTime) {
                        writeLog("autocamera startup");
                        sendCmds('ru 1');
                     }
                  } else {
                     if (($timenow - $modTime) > $schedulePars[SCHEDULE_AUTOCAMERAINTERVAL]) {
                        writeLog("autocamera shutdown");
                        sendCmds('md 0;ru 0');
                        //allow a bit of time to ensure it doesn't switch straight back on
                        $lastStatusTime = $timenow + 5;
                     } else {
                        $lastStatusTime = $timenow;
                     }
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
