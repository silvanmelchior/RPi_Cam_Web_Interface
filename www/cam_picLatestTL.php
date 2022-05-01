<?php
  define('BASE_DIR', dirname(__FILE__));
  header("Access-Control-Allow-Origin: *");
  $files = scandir(BASE_DIR.'/media', SCANDIR_SORT_DESCENDING);
  $found = 0;
  for($i = 0; $i < count(files); $i++) {
	$newest_file = $files[$i];
	if(substr($newest_file,0,2) == "tl") {
		$found = 1;
		break;
	}
  }
  if($found) {
	header("Content-Type: image/jpeg");
	readfile("media/$newest_file");
  } else {
	header("Content-Type: image/txt");
	return("Not found");  
  }
?>
