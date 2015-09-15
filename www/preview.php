<?php
   define('BASE_DIR', dirname(__FILE__));
   require_once(BASE_DIR.'/config.php');
  
   //Text labels here
   define('BTN_DOWNLOAD', 'Download');
   define('BTN_DELETE', 'Delete');
   define('BTN_CONVERT', 'Start Convert');
   define('BTN_DELETEALL', 'Delete All');
   define('BTN_DELETESEL', 'Delete Sel');
   define('BTN_SELECTALL', 'Select All');
   define('BTN_SELECTNONE', 'Select None');
   define('BTN_GETZIP', 'Get Zip');
   define('BTN_UPDATESIZEORDER', 'Update Settings');
   define('TXT_PREVIEW', 'Preview');
   define('TXT_THUMB', 'Thumb');
   define('TXT_FILES', 'Files');
   
   define('CONVERT_CMD', 'convertCmd.txt');
   
   
   //Set size defaults and try to get from cookies
   $previewSize = 640;
   $thumbSize = 96;
   $sortOrder = 1;
   $showTypes = 1;
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
   $dSelect = "";
   $pFile = "";
   $tFile = "";
   $debugString = "";
   
   if(isset($_GET['preview'])) {
      $tFile = $_GET['preview'];
      $pFile = dataFilename($tFile);
   }

   if (isset($_GET['zipprogress'])) {
      $zipname = $_GET['zipprogress'];
      $ret = @file_get_contents("$zipname.count");
      if ($ret) {
         echo $ret;
      }
      else {
         echo "complete";
      }
      return;
   }

   $zipname = false;
   //Process any POST data
   // 1 file based commands
   if (isset($_POST['zipdownload'])) {
      $zipname = $_POST['zipdownload'];
      header("Content-Type: application/zip");
      header("Content-Disposition: attachment; filename=\"".substr($zipname,strlen(MEDIA_PATH)+1)."\"");
      readfile("$zipname");
      if(file_exists($zipname)){
          unlink($zipname);
      }                  
      return;
   }
   else if (isset($_POST['delete1'])) {
      deleteFile($_POST['delete1']);
      maintainFolders(MEDIA_PATH, false, false);
   } else if (isset($_POST['convert'])) {
      $tFile = $_POST['convert'];
      startVideoConvert($tFile);
      $tFile = "";
   } else if (isset($_POST['download1'])) {
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
                  deleteFile($check);
               }
            }        
            maintainFolders(MEDIA_PATH, false, false);
            break;
         case 'updateSizeOrder':
            if(!empty($_POST['previewSize'])) {
               $previewSize = $_POST['previewSize'];
               if ($previewSize < 100 || $previewSize > 1920) $previewSize = 640;
               setcookie("previewSize", $previewSize, time() + (86400 * 365), "/");
            }        
            if(!empty($_POST['thumbSize'])) {
               $thumbSize = $_POST['thumbSize'];
               if ($thumbSize < 32 || $thumbSize > 320) $thumbSize = 96;
               setcookie("thumbSize", $thumbSize, time() + (86400 * 365), "/");
            }        
            if(!empty($_POST['sortOrder'])) {
               $sortOrder = $_POST['sortOrder'];
               setcookie("sortOrder", $sortOrder, time() + (86400 * 365), "/");
            }        
            if(!empty($_POST['showTypes'])) {
               $showTypes = $_POST['showTypes'];
               setcookie("showTypes", $showTypes, time() + (86400 * 365), "/");
            }        
            break;
         case 'zipSel':
            if (!empty($_POST['check_list'])) {
               $zipname = getZip($_POST['check_list']);
            }
            break;
      }
   }
  
   function getZip($files) {
      $zipname = MEDIA_PATH . '/cam_' . date("Ymd_His") . '.zip';
      writeLog("Making zip $zipname");
      $zipfiles = fopen($zipname.".files", "w");
      foreach ($files as $file) {
         $t = getFileType($file);
         if ($t == 't') {
            $lapses = findLapseFiles($file);
            if (!empty($lapses)) {
               foreach($lapses as $lapse) {
                  fprintf($zipfiles, "$lapse\n");
               }
            }
         } else {
            $base = dataFilename($file);
            if (file_exists(MEDIA_PATH . "/$base")) {
               fprintf($zipfiles, MEDIA_PATH . "/$base\n");
            }
            if ($t == 'v' && file_exists(MEDIA_PATH . "/$base.dat")) {
               fprintf($zipfiles, MEDIA_PATH . "/$base.dat\n");
            }
         }
      }
      fclose($zipfiles);
      file_put_contents("$zipname.count", "0/100");
      exec("./raspizip.sh $zipname $zipname.files > /dev/null &");
      return $zipname;
   }

   function startVideoConvert($bFile) {
      global $debugString;
      $tFiles = findLapseFiles($bFile);
      $tmp = BASE_DIR . '/' . MEDIA_PATH . '/' . getFileType($bFile) . getFileIndex($bFile);
      if (!file_exists($tmp)) {
         mkdir($tmp, 0777, true);
      }
      $i= 1;
      foreach($tFiles as $tFile) {
         copy($tFile, $tmp . '/' . sprintf('i_%05d', $i) . '.jpg');
         $i++;
      }
      $vFile = substr(dataFilename($bFile), 0, -3) . 'mp4';
      $cmd = $_POST['convertCmd'];
      $fp = fopen(BASE_DIR . '/' . CONVERT_CMD, 'w');
      fwrite($fp, $cmd);
      fclose($fp);
      $cmd = "(" . str_replace("i_%05d", "$tmp/i_%05d", $cmd) . ' ' . BASE_DIR . '/' . MEDIA_PATH . "/$vFile ; rm -rf $tmp;) >/dev/null 2>&1 &";
      writeLog("start lapse convert:$cmd");
      system($cmd);
      copy(MEDIA_PATH . "/$bFile", MEDIA_PATH . '/' . $vFile . '.v' . getFileIndex($bFile) .THUMBNAIL_EXT);
      writeLog("Convert finished");
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
              unlink($file);
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
      $fWidth = max($ts + 4, 140);
      echo "<fieldset class='fileicon' style='width:" . $fWidth . "px;'>";
      echo "<legend class='fileicon'>";
      echo "<button type='submit' name='delete1' value='$f' class='fileicondelete' style='background-image:url(delete.png);
'></button>";
      echo "&nbsp;&nbsp;$fNumber&nbsp;";
      echo "<img src='$fIcon' style='width:24px'/>";
      echo "<input type='checkbox' name='check_list[]' $sel value='$f' style='float:right;'/>";
      echo "</legend>";
      if ($fsz > 0) echo "$fsz Kb $lapseCount $duration"; else echo 'Busy';
      echo "<br>$fDate<br>$fTime<br>";
      if ($fsz > 0) echo "<a title='$rFile' href='preview.php?preview=$f'>";
      echo "<img src='" . MEDIA_PATH . "/$f' style='width:" . $ts . "px'/>";
      if ($fsz > 0) echo "</a>";
      echo "</fieldset> ";
   }
   
   function getThumbnails() {
      global $sortOrder;
      global $showTypes;
      $files = scandir(MEDIA_PATH, $sortOrder - 1);
      $thumbnails = array();
      foreach($files as $file) {
         if($file != '.' && $file != '..' && isThumbnail($file)) {
            $fType = getFileType($file);
            if($showTypes == '1') {
               $thumbnails[] = $file;
            }
            elseif($showTypes == '2' && ($fType == 'i' || $fType == 't')) {
               $thumbnails[] = $file;
           }
            elseif($showTypes == '3' && ($fType == 'v')) {
               $thumbnails[] = $file; 
            }
         }
      }
      return $thumbnails;   
   }
   
   function diskUsage() {
      //Get disk data
      $totalSize = round(disk_total_space(BASE_DIR . '/' . MEDIA_PATH) / 1048576); //MB
      $currentAvailable = round(disk_free_space(BASE_DIR . '/' . MEDIA_PATH) / 1048576); //MB
      $percentUsed = round(($totalSize - $currentAvailable)/$totalSize * 100, 1);
      if ($percentUsed > 98)
         $colour = 'Red';
      else if ($percentUsed > 90)
         $colour = 'Orange';
      else
         $colour = 'LightGreen';
      echo '<div style="margin-left:5px;position:relative;width:300px;border:1px solid #ccc;">';
         echo "<span>Used:$percentUsed%  Total:$totalSize(MB)</span>";
         echo "<div style='z-index:-1;position:absolute;top:0px;width:$percentUsed%;background-color:$colour;'>&nbsp;</div>";
      echo '</div>';
   }
   
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
   </head>
   <body>
      <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
         <div class="container">
            <div class="navbar-header">
               <a class="navbar-brand" href="<?php echo ROOT_PHP; ?>"><span class="glyphicon glyphicon-chevron-left"></span>Back - <?php echo CAM_STRING; ?></a>
            </div>
         </div>
      </div>
    
      <div id="progress" style="text-align:center;margin-left:20px;width:500px;border:1px solid #ccc;">&nbsp;</div>
    
      <div class="container-fluid">
      <form action="preview.php" method="POST">
      <?php
         $thumbnails = getThumbnails();
         if ($pFile != "") {
            $pIndex = array_search($tFile, $thumbnails);
            echo "<h1>" . TXT_PREVIEW . ":  " . getFileType($tFile) . getFileIndex($tFile);
            if ($pIndex > 0)
               $attr = 'onclick="location.href=\'preview.php?preview=' . $thumbnails[$pIndex-1] . '\'"';
            else
               $attr = 'disabled';
            echo "&nbsp;&nbsp;<input type='button' value='&larr;' class='btn btn-primary' name='prev' $attr >";
            if (($pIndex+1) < count($thumbnails))
               $attr = 'onclick="location.href=\'preview.php?preview=' . $thumbnails[$pIndex+1] . '\'"';
            else
               $attr = 'disabled';
            echo "&nbsp;&nbsp;<input type='button' value='&rarr;' class='btn btn-primary' name='next' $attr>";
            echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='download1' value='$tFile'>" . BTN_DOWNLOAD . "</button>";
            echo "&nbsp;<button class='btn btn-danger' type='submit' name='delete1' value='$tFile'>" . BTN_DELETE . "</button>";
            if(getFileType($tFile) == "t") {
               $convertCmd = file_get_contents(BASE_DIR . '/' . CONVERT_CMD);
               echo "&nbsp;<button class='btn btn-primary' type='submit' name='convert' value='$tFile'>" . BTN_CONVERT . "</button>";
               echo "<br></h1>Convert using: <input type='text' size=72 name = 'convertCmd' id='convertCmd' value='$convertCmd'><br><br>";
            } else {
               echo "<br></h1>";
            }
            if(substr($pFile, -3) == "jpg") {
               echo "<a href='" . MEDIA_PATH . "/$tFile' target='_blank'><img src='" . MEDIA_PATH . "/$pFile' width='" . $previewSize . "px'></a>";
            } else {
               echo "<video width='" . $previewSize . "px' controls><source src='" . MEDIA_PATH . "/$pFile' type='video/mp4'>Your browser does not support the video tag.</video>";
            }
         }
         echo "<h1>" . TXT_FILES . "&nbsp;&nbsp;";
         echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='selectNone'>" . BTN_SELECTNONE . "</button>";
         echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='selectAll'>" . BTN_SELECTALL . "</button>";
         echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='zipSel'>" . BTN_GETZIP . "</button>";
         echo "&nbsp;&nbsp;<button class='btn btn-danger' type='submit' name='action' value='deleteSel' onclick=\"return confirm('Are you sure?');\">" . BTN_DELETESEL . "</button>";
         echo "&nbsp;&nbsp;<button class='btn btn-danger' type='submit' name='action' value='deleteAll' onclick=\"return confirm('Are you sure?');\">" . BTN_DELETEALL . "</button>";
         echo "</h1>";
         diskUsage();
         if ($debugString !="") echo "$debugString<br>";
         if(count($thumbnails) == 0) echo "<p>No videos/images saved</p>";
         else {
            foreach($thumbnails as $file) {
              drawFile($file, $thumbSize, $dSelect);
            }
         }
         echo "<p><p>" . TXT_PREVIEW . " <input type='text' size='4' name='previewSize' value='$previewSize'>";
         echo "&nbsp;&nbsp;" . TXT_THUMB . " <input type='text' size='3' name='thumbSize' value='$thumbSize'>";
         echo "&nbsp;Sort Order&nbsp;<select id='sortOrder' name='sortOrder'>";
         if ($sortOrder == 1) $selected = "selected"; else $selected = "";
         echo "<option value='1' $selected>Ascending</option>";
         if ($sortOrder == 2) $selected = "selected"; else $selected = "";
         echo "<option value='2'  $selected>Descending</option>";
         echo '</select>';
         echo "&nbsp;File Types&nbsp;<select id='showTypes' name='showTypes'>";
         if ($showTypes == 1) $selected = "selected"; else $selected = "";
         echo "<option value='1' $selected>Images and Videos</option>";
         if ($showTypes == 2) $selected = "selected"; else $selected = "";
         echo "<option value='2'  $selected>Images only</option>";
         if ($showTypes == 3) $selected = "selected"; else $selected = "";
         echo "<option value='3'  $selected>Videos only</option>";
         echo '</select>';
         echo "&nbsp;&nbsp;<button class='btn btn-primary' type='submit' name='action' value='updateSizeOrder'>" . BTN_UPDATESIZEORDER . "</button>";
      ?>
      </form>
      
      <form id="zipform" method="post" action="preview.php" style="display:none;">
         <input id="zipdownload" type="hidden" name="zipdownload"/>
      </form>
      
      </div>
      
      <?php 
      if ($zipname) {
         echo '<script language="javascript">get_zip_progress("' . $zipname . '");</script>';
      } else {
         echo '<script language="javascript">document.getElementById("progress").style.display="none";</script>';
      }
      ?>
   </body>
</html>
