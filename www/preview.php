<?php
   define('BASE_DIR', dirname(__FILE__));
   require_once(BASE_DIR.'/config.php');
  
   //Text labels here
   define('BTN_DOWNLOAD', 'Download');
   define('BTN_DELETE', 'Delete');
   define('BTN_DELETE_CONFIRM', 'Are you sure you want to delete this file?');
   define('BTN_CONVERT', 'Start Convert');
   define('BTN_DELETEALL', 'Delete All');
   define('BTN_DELETEALL_CONFIRM', 'Are you sure you want to delete all items?');
   define('BTN_DELETESEL', 'Delete Selected');
   define('BTN_DELETESEL_CONFIRM', 'Are you sure you want to delete selected items?');
   define('BTN_SELECTALL', 'Select All');
   define('BTN_SELECTNONE', 'Deselect');
   define('BTN_GETZIP', 'Get Zip');
   define('BTN_LOCKSEL', 'Lock Sel');
   define('BTN_UNLOCKSEL', 'Unlock Selected');
   define('BTN_UPDATESIZEORDER', 'Update');
   define('TXT_PREVIEW', 'Preview');
   define('TXT_THUMB', 'Thumb');
   define('TXT_FILES', 'Files');
   
   define('CONVERT_CMD', 'convertCmd.txt');
   
   //Set to top or bottom to position controls
   define('CONTROLS_POS', 'top');
   
   //Set size defaults and try to get from cookies
   $previewSize = 640;
   $thumbSize = 96;
   $sortOrder = 1;
   $showTypes = 1;
   $timeFilter = 1;
   $timeFilterMax = 8;
   if(isset($_COOKIE["previewSize"])) {
      $previewSize = $_COOKIE["previewSize"];
   }
   if(isset($_COOKIE["thumbSize"])) {
      $thumbSize = $_COOKIE["thumbSize"];
   }
   if(isset($_COOKIE["sortOrder"])) {
      $sortOrder = $_COOKIE["sortOrder"];
   }
   if(isset($_COOKIE["showTypes"])) {
      $showTypes = $_COOKIE["showTypes"];
   }
   if(isset($_COOKIE["timeFilter"])) {
      $timeFilter = $_COOKIE["timeFilter"];
   }
   $dSelect = "";
   $pFile = "";
   $tFile = "";
   $debugString = "";
   
   if(isset($_GET['preview'])) {
      $tFile = $_GET['preview'];
      $pFile = dataFilename($tFile);
   }

   $zipname = false;
   $user = getUser();
   $userLevel = getUserLevel($user);
   //Process any POST data
   if (isset($_POST['timeFilter'])){
	   $timeFilter = $_POST['timeFilter'];
	   setcookie("timeFilter", $timeFilter, time() + (86400 * 365), "/");
   }
   if (isset($_POST['sortOrder'])){
	   $sortOrder = $_POST['sortOrder'];
	   setcookie("sortOrder", $sortOrder, time() + (86400 * 365), "/");
   }
   if (isset($_POST['showTypes'])){
	   $showTypes = $_POST['showTypes'];
	   setcookie("showTypes", $showTypes, time() + (86400 * 365), "/");
   }
   if (isset($_POST['delete1']) && checkMediaPath($_POST['delete1'])) {
	 deleteFile($_POST['delete1']);
     maintainFolders(MEDIA_PATH, false, false);
   } else if (isset($_POST['convert'])) {
      $tFile = $_POST['convert'];
      startVideoConvert($tFile);
      $tFile = "";
   } else if (isset($_POST['download1'])  && checkMediaPath($_POST['download1'])) {
      $dFile = $_POST['download1'];
      if(getFileType($dFile) != 't') {
         $dxFile = dataFilename($dFile);
         if(dataFileext($dFile) == "jpg") {
            header("Content-Type: image/jpeg");
         } else {
            header("Content-Type: video/mp4");
         }
         header("Content-Disposition: attachment; filename=\"" . dataFilename($dFile) . "\"");
         readfile(MEDIA_PATH . "/$dxFile");
         return;
      } else {
         $zipname = getZip(array($dFile));
      }
   } else if (isset($_POST['action'])){
      //global commands
      switch($_POST['action']) {
         case 'deleteAll':
            maintainFolders(MEDIA_PATH, true, true);
            break;
         case 'selectAll':
            $dSelect = "checked";
            break;
         case 'selectNone':
            $dSelect = "";
            break;
         case 'deleteSel':
            if(!empty($_POST['check_list'])) {
               foreach($_POST['check_list'] as $check) {
                  if (checkMediaPath($check)) {
					  deleteFile($check);
				  }
               }
            }        
            maintainFolders(MEDIA_PATH, false, false);
            break;
         case 'lockSel':
            if(!empty($_POST['check_list'])) {
               foreach($_POST['check_list'] as $check) {
                  if (checkMediaPath($check)) {
					  lockFile($check, 1);
				  }
               }
            }        
            break;
         case 'unlockSel':
            if(!empty($_POST['check_list'])) {
               foreach($_POST['check_list'] as $check) {
                  if (checkMediaPath($check)) {
					  lockFile($check, 0);
				  }
               }
            }        
            break;
         case 'updateSizeOrder':
            if(!empty($_POST['previewSize'])) {
               $previewSize = $_POST['previewSize'];
               $previewSize = max($previewSize,100);
			   $previewSize = min($previewSize, 1920);
               setcookie("previewSize", $previewSize, time() + (86400 * 365), "/");
            }        
            if(!empty($_POST['thumbSize'])) {
               $thumbSize = $_POST['thumbSize'];
               $thumbSize = max($thumbSize, 32);
			   $thumbSize = min($thumbSize, 320);
               setcookie("thumbSize", $thumbSize, time() + (86400 * 365), "/");
            }        
            break;
         case 'zipSel':
            if (!empty($_POST['check_list'])) {
                getZip($_POST['check_list']);
                return;
            }
            echo "No files selected to zip."; 
            break;
      }
   }
   
   function pvDisplayStyle($style) {
	 global $userLevel;
	 if ((int)$userLevel < (int)USERLEVEL_MEDIUM)
	   return "style='display:none;'";
     else if(strlen($style) > 0)
	   return "style='$style'";
     else
	   return '';
   }
   
   function checkMediaPath($path) {
	   return ((realpath(dirname(MEDIA_PATH . "/$path")) == realpath(MEDIA_PATH)) && file_exists(MEDIA_PATH . "/$path"));
   }
  
   function getZip($files) {
      $zipname = 'cam_' . date("Ymd_His") . '.zip';
      $cmd = 'zip -0 -q -'; // Don't compress!
      $size = 1000000;
      foreach ($files as $file) {
		 if(checkMediaPath($file)) {
           $t = getFileType($file);
           if ($t == 't') {
              $lapses = findLapseFiles($file);
              if (!empty($lapses)) {
                foreach($lapses as $lapse) {
                  $cmd .= " $lapse";
                  $size += filesize($lapse);
                }
              }
           } else if ($t == 'v' || $t == 'i') {
              $base = dataFilename($file);
              $f = MEDIA_PATH . "/$base";
              if (file_exists($f)) {
                $cmd .= " $f";
                $size += filesize($f);
              }
              $f = MEDIA_PATH . "/$base.dat";
              if ($t == 'v' && file_exists($f)) {
                $cmd .= " $f";
                $size += filesize($f);
              }
           }
		 }
      }
      writeLog("Generating ZIP using command: $cmd ($size bytes)");

      header("Content-Type: application/zip");
      header("Content-Disposition: attachment; filename=\"".$zipname."\"");
      //header("Content-Length: " . $size); // not working (yet)

      $zipStream = popen($cmd, "r");
      fpassthru($zipStream);
      pclose($zipStream);
      flush();
   }

   function startVideoConvert($bFile) {
      global $debugString;
	  if(checkMediaPath($bFile)) { 
	    $ft = getFileType($bFile);
	    $fi = getFileIndex($bFile);
	    if($ft =='t' && is_numeric($fi)) {
		  $tFiles = findLapseFiles($bFile);
		  $tmp = BASE_DIR . '/' . MEDIA_PATH . '/' . $ft . $fi;
		  if (!file_exists($tmp)) {
			 mkdir($tmp, 0777, true);
		  }
		  $i= 0;
		  foreach($tFiles as $tFile) {
			 symlink($tFile, $tmp . '/' . sprintf('i_%05d', $i) . '.jpg');
			 $i++;
		  }
		  $vFile = substr(dataFilename($bFile), 0, -3) . 'mp4';
		  $fp = fopen(BASE_DIR . '/' . CONVERT_CMD, 'r');
		  $cmd = trim(fgets($fp));
		  fclose($fp);
		  $cmd = "(" . str_replace("i_%05d", "$tmp/i_%05d", $cmd) . " " . BASE_DIR . '/' . MEDIA_PATH . "/$vFile ; rm -rf $tmp;) >/dev/null 2>&1 &";
		  writeLog("start lapse convert:$cmd");
		  system($cmd);
		  copy(MEDIA_PATH . "/$bFile", MEDIA_PATH . '/' . $vFile . '.v' . getFileIndex($bFile) .THUMBNAIL_EXT);
		  writeLog("Convert finished");
	    }
	  }
   }


   // function to deletes files and folders recursively
   // $deleteMainFiles true r false to delete files from the top level folder
   // $deleteSubFiles true or false to delete files from subfolders
   // Empty subfolders get removed.
   // $root true or false. If true (default) then top dir not removed
   function maintainFolders($path, $deleteMainFiles, $deleteSubFiles, $root = true) {
      $empty=true;
      foreach (glob("$path/*") as $file) {
         if (is_dir($file)) {
            if (!maintainFolders($file, $deleteMainFiles, $deleteSubFiles, false)) $empty=false;
         }  else {
            if (($deleteSubFiles && !$root) || ($deleteMainFiles && $root)) {
              if(is_writeable($file)) unlink($file);
            } else {
               $empty=false;
            }
         }
      }
      return $empty && !$root && rmdir($path);
   }
   
   //function to draw 1 file on the page
   function drawFile($f, $ts, $sel) {
      $fType = getFileType($f);
      $rFile = dataFilename($f);
      $fNumber = getFileIndex($f);
      $lapseCount = "";
      switch ($fType) {
         case 'v': $fIcon = 'video.png'; break;
         case 't': 
            $fIcon = 'timelapse.png';
            $lapseCount = '(' . count(findLapseFiles($f)). ')';
            break;
         case 'i': $fIcon = 'image.png'; break;
         default : $fIcon = 'image.png'; break;
      }
      $duration ='';
      if (file_exists(MEDIA_PATH . "/$rFile")) {
         $fsz = round ((filesize_n(MEDIA_PATH . "/$rFile")) / 1024);
         $fModTime = filemtime(MEDIA_PATH . "/$rFile");
         if ($fType == 'v') {
            $duration = ($fModTime - filemtime(MEDIA_PATH . "/$f")) . 's';
         }
      } else {
         $fsz = 0;
         $fModTime = filemtime(MEDIA_PATH . "/$f");
      }
      $fDate = @date('Y-m-d', $fModTime);
      $fTime = @date('H:i:s', $fModTime);
      $fWidth = max($ts + 4, 150);
      echo "<fieldset class='fileicon' style='width:" . $fWidth . "px;'>";
      echo "<legend class='fileicon'>";
	  if(is_writeable(MEDIA_PATH . "/$f")) {
		echo "<button type='submit' name='delete1' value='$f' class='fileicondelete' " . pvDisplayStyle("background-image:url(delete.png);") . " onclick='return confirm(\"".BTN_DELETE_CONFIRM."\");'></button>";
	  } 
      echo "&nbsp;&nbsp;<a target=\"_blank\" href=\"" . MEDIA_PATH . "/$rFile\">$fNumber</a>&nbsp;";
      echo "<img src='$fIcon' style='width:24px'/>";
      echo "<input type='checkbox' name='check_list[]' $sel value='$f' " . pvDisplayStyle("float:right;") . "/>";
      echo "</legend>";
	   
     if ($fsz > 0) {
	      if($fsz > 1024) {
	    	 echo round($fsz/1024) . " MB";
	      } else {
	     	 echo "$fsz KB";
	      }
	      echo " $lapseCount $duration";
      } else {
	      echo 'Busy';
      }
      echo "<br>$fDate<br>$fTime<br>";
      if ($fsz > 0) echo "<a title='$rFile' href='#' onclick='load_preview(\"$f\");'>";
      echo "<img src='" . MEDIA_PATH . "/$f' style='width:" . $ts . "px'/>";
      if ($fsz > 0) echo "</a>";
      echo "</fieldset> ";
   }
   
   function getThumbnails() {
      global $sortOrder;
      global $showTypes;
      global $timeFilter, $timeFilterMax;
      //$files = scandir(MEDIA_PATH, $sortOrder - 1);
      $files = scandir(MEDIA_PATH);
      $thumbnails = array();
      $nowTime = time();
      foreach($files as $file) {
         if($file != '.' && $file != '..' && isThumbnail($file)) {
			 $fTime = filemtime(MEDIA_PATH . "/$file");
            if ($timeFilter == 1) {
               $include = true;
            } else {
               $timeD = $nowTime - $fTime;
               if ($timeFilter == $timeFilterMax) {
                  $include = ($timeD >= 86400 * ($timeFilter - 2));
               } else {
                  $include = ($timeD >= (86400 * ($timeFilter - 2))) && ($timeD < (($timeFilter - 1) * 86400));
               }
            }
            if($include) {
               $fType = getFileType($file);
               if(($showTypes == '1') || ($showTypes == '2' && ($fType == 'i' || $fType == 't')) || ($showTypes == '3' && ($fType == 'v'))) {
                  $thumbnails[$file] = $fType . $fTime;
               }
            }
         }
      }
	  if ($sortOrder == 1) {
		  asort($thumbnails);
	  } else {
		  arsort($thumbnails);
	  }
	  $thumbnails = array_keys($thumbnails);
      return $thumbnails;   
   }
   
function diskUsage() {
      //Get disk data
      echo '<div style="margin-left:5px;position:relative;width:300px;border:1px solid #ccc;margin-bottom: 1em;">';
	  if (file_exists("diskUsage.txt")) {
		$data = file_get_contents("diskUsage.txt");
		$lines =  explode("\n", $data);
	  } else {
		  $lines = array("local:local");
	  }
	  $br = "";
	  $px = 0;
	  foreach($lines as $line) {
	    $fields = explode(':', $line);
		if(strlen($line) > 3 && count($fields) > 1) {
		  if($fields[1] == 'local') $fields[1] = BASE_DIR . '/' . MEDIA_PATH;
	      $totalSize = round(disk_total_space($fields[1]) / 1048576); //MB
	      $currentAvailable = round(disk_free_space($fields[1]) / 1048576); //MB
	      $percentUsed = round(($totalSize - $currentAvailable)/$totalSize * 100, 1);
	      if ($percentUsed > 98)
		    $colour = 'Red';
	      else if ($percentUsed > 90)
		    $colour = 'Orange';
	      else
		    $colour = 'LightGreen';
	      echo $br . "<span>" . $fields[0] . ": $percentUsed%  Total: $totalSize MB</span>";
	      echo "<div style='z-index:-1;position:absolute;top:" . $px . "px;width:$percentUsed%;background-color:$colour;'>&nbsp;</div>";
		  $br = '<br>';
		  $px = $px + 20;
		}
	  }
      echo '</div>';
   }
   
   function settingsControls() {
      global $previewSize,$thumbSize,$sortOrder, $showTypes;
      global $timeFilter, $timeFilterMax;
      
      echo TXT_PREVIEW . " <input type='number' name='previewSize' value='$previewSize' style='width: 4em;'>";
      echo "&nbsp;&nbsp;" . TXT_THUMB . " <input type='number' name='thumbSize' value='$thumbSize' style='width: 4em;'>";
      echo "&nbsp;<button class='btn btn-primary' type='submit' name='action' value='updateSizeOrder'>" . BTN_UPDATESIZEORDER . "</button>";
      echo '&nbsp;Sort&nbsp;<select id="sortOrder" name="sortOrder" onchange="this.form.submit()">';
      if ($sortOrder == 1) $selected = "selected"; else $selected = "";
      echo "<option value='1' $selected>Ascending</option>";
      if ($sortOrder == 2) $selected = "selected"; else $selected = "";
      echo "<option value='2'  $selected>Descending</option>";
      echo '</select>';
      echo '&nbsp;Types&nbsp;<select id="showTypes" name="showTypes" onchange="this.form.submit()">';
      if ($showTypes == 1) $selected = "selected"; else $selected = "";
      echo "<option value='1' $selected>Images &amp Videos</option>";
      if ($showTypes == 2) $selected = "selected"; else $selected = "";
      echo "<option value='2'  $selected>Images only</option>";
      if ($showTypes == 3) $selected = "selected"; else $selected = "";
      echo "<option value='3'  $selected>Videos only</option>";
      echo '</select>';
      echo '&nbsp;Filter&nbsp;<select id="timeFilter" name="timeFilter" onchange="this.form.submit()">';
      if ($timeFilter == 1) $selected = "selected"; else $selected = "";
      echo "<option value='1' $selected>All</option>";
      for($tf = 2; $tf < $timeFilterMax;$tf++) {
         if ($timeFilter == $tf) $selected = "selected"; else $selected = "";
         $tfStr = ($tf-2) * 24 . '-' . ($tf-1) * 24 . ' hours old';
         echo "<option value='$tf'  $selected>$tfStr</option>";
      }
      if ($timeFilter >= $timeFilterMax) $selected = "selected"; else $selected = "";
      $tfStr = ($timeFilterMax-2) * 24 . '+ hours old';
      echo "<option value='$timeFilterMax'  $selected>$tfStr</option>";
      echo '</select>';
	  echo '<br>';
   }
   $f = fopen(BASE_DIR . '/' . CONVERT_CMD, 'r');
   $convertCmd = trim(fgets($f));
   fclose($f);
   $thumbnails = getThumbnails();
?>
<!DOCTYPE html>
<html>
   <head>
      <meta name="viewport" content="width=550, initial-scale=1">
      <title><?php echo CAM_STRING; ?> Download</title>
      <link rel="stylesheet" href="css/style_minified.css" />
      <link rel="stylesheet" href="css/preview.css" />
      <link rel="stylesheet" href="<?php echo getStyle(); ?>" />
      <script src="js/style_minified.js"></script>
      <script src="js/script.js"></script>
      <script src="js/preview.js"></script>
      <script>
         var thumbnails = <?php echo json_encode($thumbnails) ?>;
         var linksBase = 'preview.php?preview=';
         var mediaBase = "<?php echo MEDIA_PATH . '/' ?>";
         var previewWidth = <?php echo $previewSize ?>;
      </script>

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
      <form action="preview.php" method="POST">
         <div id='preview' style="display: none; min-height: <?php echo $previewSize ?>px">
            <h1 <?php echo pvDisplayStyle(''); ?>>
               <?php echo TXT_PREVIEW ?>: <span id='media-title'></span>
               <input type='button' value='&larr;' class='btn btn-primary' name='prev'>
               <input type='button' value='&rarr;' class='btn btn-primary' name='next'>

               <button class='btn btn-primary' type='submit' name='download1'><?php echo BTN_DOWNLOAD; ?></button>
               <button class='btn btn-danger' type='submit' name='delete1' onclick='return confirm("<?php echo BTN_DELETE_CONFIRM; ?>");'><?php echo BTN_DELETE; ?></button>
               
               <button class='btn btn-primary' type='submit' name='convert'><?php echo BTN_CONVERT ?></button>
               <br>
            </h1>

            <div id='media'></div>
         </div>

         <script>
            var thumbnail = getParameterByName('preview');
            if (thumbnail) {
               load_preview(thumbnail);
            }
         </script>

         <h1 <?php echo pvDisplayStyle(''); ?>><?php echo TXT_FILES; ?>
         <button class='btn btn-primary' type='submit' name='action' value='selectNone'><?php echo BTN_SELECTNONE; ?></button>
         <button class='btn btn-primary' type='submit' name='action' value='selectAll'><?php echo BTN_SELECTALL; ?></button>
         <button class='btn btn-primary' type='submit' name='action' value='zipSel'><?php echo BTN_GETZIP; ?></button>
         <button class='btn btn-warning' type='submit' name='action' value='deleteSel' onclick="return confirm('<?php echo BTN_DELETESEL_CONFIRM; ?>')"><?php echo BTN_DELETESEL; ?></button>
         <button class='btn btn-danger' type='submit' name='action' value='deleteAll' onclick="return confirm('<?php echo BTN_DELETEALL_CONFIRM; ?>')"><?php echo BTN_DELETEALL; ?></button>
         <button class='btn btn-primary' type='submit' name='action' value='lockSel'><?php echo BTN_LOCKSEL; ?></button>
         <button class='btn btn-primary' type='submit' name='action' value='unlockSel'><?php echo BTN_UNLOCKSEL; ?></button>
         </h1>
         <?php
         diskUsage();
         if(CONTROLS_POS == 'top') settingsControls();
         if ($debugString !="") echo "$debugString<br>";
         if(count($thumbnails) == 0) echo "<p>No videos/images saved</p>";
         else {
            foreach($thumbnails as $file) {
              drawFile($file, $thumbSize, $dSelect);
            }
         }
         if(CONTROLS_POS == 'bottom') {echo "<br>";settingsControls();}
      ?>
      </form>
      
      </div>
   </body>
</html>
