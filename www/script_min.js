//
// MJPEG
//
var mjpeg_img;

function reload_img () {
  mjpeg_img.src = "cam_pic.php?time=" + new Date().getTime();
}

function error_img () {
  setTimeout("mjpeg_img.src = 'cam_pic.php?time=' + new Date().getTime();", 100);
}

//
// Init
//
function init() {

  // mjpeg
  mjpeg_img = document.getElementById("mjpeg_dest");
  mjpeg_img.onload = reload_img;
  mjpeg_img.onerror = error_img;
  reload_img();

}
