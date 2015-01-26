<!DOCTYPE html>
<?php
  define('BASE_DIR', dirname(__FILE__));
  require_once(BASE_DIR.'/config.php');
?>
<html>
  <head>
  	<meta name="viewport" content="width=550, initial-scale=1">
    <title><?php echo CAM_STRING; ?></title>
    <link rel="stylesheet" href="css/app.css" />
    <script src="js/app.js"></script>
    <script src="script.js"></script>
  </head>
  <body onload="setTimeout('init();', 100);">
  	<div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
  		<div class="container">
			<div class="navbar-header">
				<a class="navbar-brand" href="#"><?php echo CAM_STRING; ?></a>
			</div>
		</div>
  	</div>

	<div class="container-fluid text-center liveimage">
      <div><img id="mjpeg_dest"></div>
      <input id="video_button" type="button" class="btn btn-primary">
      <input id="image_button" type="button" class="btn btn-primary">
      <input id="timelapse_button" type="button" class="btn btn-primary">
      <input id="md_button" type="button" class="btn btn-primary">
      <input id="halt_button" type="button" class="btn btn-danger">
  	</div>
  	<div class="container-fluid text-center">
		<a href="preview.php" class="btn btn-default">Download Videos and Images</a>
  	</div>
  	<div class="container-fluid text-center">
  		<div class="panel-group" id="accordion">
  			<div class="panel panel-default">
  				<div class="panel-heading">
		  			<h2 class="panel-title">
		  			<a data-toggle="collapse" data-parent="#accordion" href="#collapseOne">Settings</a>
		  			</h2>
				</div>
				<div id="collapseOne" class="panel-collapse collapse">
					<div class="panel-body">
					  <table class="settingsTable">
						<tr>
						  <td>Resolutions:</td>
						  <td>
							Load Preset: <select onclick="set_preset(this.value)">
							  <option value="1920 1080 25 25 2592 1944">Select option...</option>
							  <option value="1920 1080 25 25 2592 1944">Std FOV</option>
							  <option value="1296 0730 25 25 2592 1944">16:9 wide FOV</option>
							  <option value="1296 0976 25 25 2592 1944">4:3 full FOV</option>
							  <option value="1920 1080 01 30 2592 1944">Std FOV, x30 Timelapse</option>
							</select><br>
							Custom Values:<br>
							Video res: <input type="text" size=4 id="video_width">x<input type="text" size=4 id="video_height">px<br>
							Video fps: <input type="text" size=2 id="video_fps">recording, <input type="text" size=2 id="MP4Box_fps">boxing<br>
							Image res: <input type="text" size=4 id="image_width">x<input type="text" size=4 id="image_height">px<br>
							<input type="button" value="OK" onclick="set_res();">
						  </td>
						</tr>
						<tr>
						  <td>Timelapse-Interval (0.1...3200):</td>
						  <td><input type="text" size=4 id="tl_interval" value="3">s</td>
						</tr>
						<tr>
						  <td>Annotation (max 31 characters):</td>
						  <td>
							Text: <input type="text" size=20 id="annotation"><input type="button" value="OK" onclick="send_cmd('an ' + encodeURI(document.getElementById('annotation').value))"><input type="button" value="Default" onclick="document.getElementById('annotation').value = 'RPi Cam %04d.%02d.%02d_%02d:%02d:%02d'; send_cmd('an ' + encodeURI(document.getElementById('annotation').value))"><br>
							Black background: <input type="button" value="ON" onclick="send_cmd('ab 1')"><input type="button" value="OFF" onclick="send_cmd('ab 0')">
						  </td>
						</tr>
						<tr>
						  <td>Sharpness (-100...100), default 0:</td>
						  <td><input type="text" size=4 id="sharpness"><input type="button" value="OK" onclick="send_cmd('sh ' + document.getElementById('sharpness').value)"></td>
						</tr>
						<tr>
						  <td>Contrast (-100...100), default 0:</td>
						  <td><input type="text" size=4 id="contrast"><input type="button" value="OK" onclick="send_cmd('co ' + document.getElementById('contrast').value)"></td>
						</tr>
						<tr>
						  <td>Brightness (0...100), default 50:</td>
						  <td><input type="text" size=4 id="brightness"><input type="button" value="OK" onclick="send_cmd('br ' + document.getElementById('brightness').value)"></td>
						</tr>
						<tr>
						  <td>Saturation (-100...100), default 0:</td>
						  <td><input type="text" size=4 id="saturation"><input type="button" value="OK" onclick="send_cmd('sa ' + document.getElementById('saturation').value)"></td>
						</tr>
						<tr>
						  <td>ISO (100...800), default 0:</td>
						  <td><input type="text" size=4 id="iso"><input type="button" value="OK" onclick="send_cmd('is ' + document.getElementById('iso').value)"></td>
						</tr>
						<tr>
						  <td>Metering Mode, default 'average':</td>
						  <td>
							<select onclick="send_cmd('mm ' + this.value)">
							  <option value="average">Select option...</option>
							  <option value="average">Average</option>
							  <option value="spot">Spot</option>
							  <option value="backlit">Backlit</option>
							  <option value="matrix">Matrix</option>
							</select>
						  </td>
						</tr>
						<tr>
						  <td>Video Stabilisation, default: 'off'</td>
						  <td><input type="button" value="ON" onclick="send_cmd('vs 1')"><input type="button" value="OFF" onclick="send_cmd('vs 0')"></td>
						</tr>
						<tr>
						  <td>Exposure Compensation (-10...10), default 0:</td>
						  <td><input type="text" size=4 id="comp"><input type="button" value="OK" onclick="send_cmd('ec ' + document.getElementById('comp').value)"></td>
						</tr>
						<tr>
						  <td>Exposure Mode, default 'auto':</td>
						  <td>
							<select onclick="send_cmd('em ' + this.value)">
							  <option value="auto">Select option...</option>
							  <option value="off">Off</option>
							  <option value="auto">Auto</option>
							  <option value="night">Night</option>
							  <option value="nightpreview">Nightpreview</option>
							  <option value="backlight">Backlight</option>
							  <option value="spotlight">Spotlight</option>
							  <option value="sports">Sports</option>
							  <option value="snow">Snow</option>
							  <option value="beach">Beach</option>
							  <option value="verylong">Verylong</option>
							  <option value="fixedfps">Fixedfps</option>
							</select>
						  </td>
						</tr>
						<tr>
						  <td>White Balance, default 'auto':</td>
						  <td>
							<select onclick="send_cmd('wb ' + this.value)">
							  <option value="auto">Select option...</option>
							  <option value="off">Off</option>
							  <option value="auto">Auto</option>
							  <option value="sun">Sun</option>
							  <option value="cloudy">Cloudy</option>
							  <option value="shade">Shade</option>
							  <option value="tungsten">Tungsten</option>
							  <option value="fluorescent">Fluorescent</option>
							  <option value="incandescent">Incandescent</option>
							  <option value="flash">Flash</option>
							  <option value="horizon">Horizon</option>
							</select>
						  </td>
						</tr>
						<tr>
						  <td>Image Effect, default 'none':</td>
						  <td>
							<select onclick="send_cmd('ie ' + this.value)">
							  <option value="none">Select option...</option>
							  <option value="none">None</option>
							  <option value="negative">Negative</option>
							  <option value="solarise">Solarise</option>
							  <option value="sketch">Sketch</option>
							  <option value="denoise">Denoise</option>
							  <option value="emboss">Emboss</option>
							  <option value="oilpaint">Oilpaint</option>
							  <option value="hatch">Hatch</option>
							  <option value="gpen">Gpen</option>
							  <option value="pastel">Pastel</option>
							  <option value="watercolour">Watercolour</option>
							  <option value="film">Film</option>
							  <option value="blur">Blur</option>
							  <option value="saturation">Saturation</option>
							  <option value="colourswap">Colourswap</option>
							  <option value="washedout">Washedout</option>
							  <option value="posterise">Posterise</option>
							  <option value="colourpoint">Colourpoint</option>
							  <option value="colourbalance">Colourbalance</option>
							  <option value="cartoon">Cartoon</option>
							</select>
						  </td>
						</tr>
						<tr>
						  <td>Colour Effect, default 'disabled':</td>
						  <td>
							<select id="ce_en">
							  <option value="0">Disabled</option>
							  <option value="1">Enabled</option>
							</select>
							u:v = <input type="text" size=3 id="ce_u">:<input type="text" size=3 id="ce_v">
							<input type="button" value="OK" onclick="set_ce();">
						  </td>
						</tr>
						<tr>
						  <td>Rotation, default 0:</td>
						  <td>
							<select onclick="send_cmd('ro ' + this.value)">
							  <option value="0">Select option...</option>
							  <option value="0">0</option>
							  <option value="90">90</option>
							  <option value="180">180</option>
							  <option value="270">270</option>
							</select>
						  </td>
						</tr>
						<tr>
						  <td>Flip, default 'none':</td>
						  <td>
							<select onclick="send_cmd('fl ' + this.value)">
							  <option value="0">Select option...</option>
							  <option value="0">None</option>
							  <option value="1">Horizonal</option>
							  <option value="2">Vertical</option>
							  <option value="3">Both</option>
							</select>
						  </td>
						</tr>
						<tr>
						  <td>Sensor Region, default 0/0/65536/65536:</td>
						  <td>
							x<input type="text" size=5 id="roi_x"> y<input type="text" size=5 id="roi_y"> w<input type="text" size=5 id="roi_w"> h<input type="text" size=5 id="roi_h"> <input type="button" value="OK" onclick="set_roi();">
						  </td>
						</tr>
						<tr>
						  <td>Shutter speed (0...330000), default 0:</td>
						  <td><input type="text" size=4 id="shutter_speed"><input type="button" value="OK" onclick="send_cmd('ss ' + document.getElementById('shutter_speed').value)"></td>
						</tr>
						<tr>
						  <td>Image quality (0...100), default 85:</td>
						  <td><input type="text" size=4 id="quality"><input type="button" value="OK" onclick="send_cmd('qu ' + document.getElementById('quality').value)"></td>
						</tr>
						<tr>
						  <td>Raw Layer, default: 'off'</td>
						  <td><input type="button" value="ON" onclick="send_cmd('rl 1')"><input type="button" value="OFF" onclick="send_cmd('rl 0')"></td>
						</tr>
						<tr>
						  <td>Video bitrate (0...25000000), default 17000000:</td>
						  <td><input type="text" size=10 id="bitrate"><input type="button" value="OK" onclick="send_cmd('bi ' + document.getElementById('bitrate').value)"></td>
						</tr>
					  </table>
				  </div>
			  </div>
  			<div class="panel panel-default">
  				<div class="panel-heading">
		  			<h2 class="panel-title">
		  			<a data-toggle="collapse" data-parent="#accordion" href="#collapseTwo">System</a>
		  			</h2>
				</div>
				<div id="collapseTwo" class="panel-collapse collapse">
					<div class="panel-body">
						<input id="shutdown_button" type="button" value="shutdown system" onclick="sys_shutdown();" class="btn btn-danger">
            			<input id="reboot_button" type="button" value="reboot system" onclick="sys_reboot();" class="btn btn-danger">
					</div>
				</div>
		</div>
    </div>
  </body>
</html>
