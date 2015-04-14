<?php
//Blantly ripped off from https://github.com/donatj/mjpeg-php/blob/master/mjpeg.php
//And then modified to suit out needs

define('BASE_DIR', dirname(__FILE__));
require_once(BASE_DIR.'/config.php');
$config = array();

$config = readConfig($config, CONFIG_FILE1);
$config = readConfig($config, CONFIG_FILE2);


$video_fps = $config['video_fps'];
$preview_devider = $config['divider'];

$preview_fps = ($video_fps / $preview_devider);
$preview_delay = floor((1/$preview_fps * 1000000));

if ($_GET[debug] == 'y')
{
	var_dump($preview_delay);
	die();
}

// Used to separate multipart
$boundary = "PIderman";

// We start with the standard headers. PHP allows us this much
header("Cache-Control: no-cache");
header("Cache-Control: private");
header("Pragma: no-cache");
header("Content-type: multipart/x-mixed-replace; boundary=$boundary");

// Set this so PHP doesn't timeout during a long stream
set_time_limit(0);
while(true) 
{
	echo "--$boundary\n";
	echo "Content-type: image/jpeg\r\n\r\n";
	
	// Per-image header, note the two new-lines
	ob_start();
	readfile("/dev/shm/mjpeg/cam.jpg");
	echo ob_get_clean(); 
	
	usleep($preview_delay);
}