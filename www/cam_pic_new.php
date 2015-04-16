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

if (isset($_GET["debug"]) && $_GET["debug"] == 'y')
{
	var_dump($preview_delay);
	die();
}

// Used to separate multipart
$boundary = "PIderman";

// We start with the standard headers. PHP allows us this much
header ("Content-type: multipart/x-mixed-replace; boundary=$boundary");
header ("Cache-Control: no-cache");
header ("Pragma: no-cache");
header ("Connection: close");

ob_flush();		//Push out the content we already have (gets the headers to the browser as quickly as possible)

set_time_limit(0); // Set this so PHP doesn't timeout during a long stream


while(true) 
{	
	ob_start();
	
	echo "--$boundary\r\n";
	echo "Content-type: image/jpeg\r\n";
	
	$fileContents = file_get_contents("/dev/shm/mjpeg/cam.jpg");
	$fileLength = strlen($fileContents);
	
	echo "Content-Length:" . $fileLength . "\r\n";
	echo "\r\n";
	
	echo $fileContents;
	
	echo "\r\n";
	ob_end_flush();
	
	usleep($preview_delay);
}