<?php
//Blantly ripped off from https://github.com/donatj/mjpeg-php/blob/master/mjpeg.php
//And then modified to suit out needs
//multiview version of cam_pic_new.php for multiple hosts

define('BASE_DIR', dirname(__FILE__));
require_once(BASE_DIR.'/config.php');
$multi = json_decode(file_get_contents("multiview.json"), true);

if (isset($_GET["rHost"])) {
		$hostI = $_GET["rHost"];
		$host = $multi["hosts"][$hostI];
		header('Location: '.$host);
	} else {
	if (isset($_GET["pHost"])) {
		$hostI = $_GET["pHost"];
	} else {
		$hostI = 0;
	}
	$host = $multi["hosts"][$hostI];
	$preview_delay = $multi["delays"][$hostI];

	//writeLog("mjpeg stream with $preview_delay delay");

	// Used to separate multipart
	$boundary = "PIderman";

	// We start with the standard headers. PHP allows us this much
	header ("Content-type: multipart/x-mixed-replace; boundary=$boundary");
	header ("Cache-Control: no-cache");
	header ("Pragma: no-cache");
	header ("Connection: close");

	ob_flush();		//Push out the content we already have (gets the headers to the browser as quickly as possible)

	set_time_limit(0); // Set this so PHP doesn't timeout during a long stream

	while(true) {
		ob_start();
		
		echo "--$boundary\r\n";
		echo "Content-type: image/jpeg\r\n";
		
		$fileContents = file_get_contents($host . 'cam_get.php');
		$fileLength = strlen($fileContents);
		
		echo "Content-Length:" . $fileLength . "\r\n";
		echo "\r\n";
		
		echo $fileContents;
		
		echo "\r\n";
		ob_end_flush();
		
		usleep($preview_delay);
	}	
}
