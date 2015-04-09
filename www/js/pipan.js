var pan = 100;
var tilt = 100;
var pan_bak = 100;
var tilt_bak = 100;
var pan_start;
var tilt_start;
var touch = false;
var led_stat = false;
var ajax_pipan;
var pipan_mouse_x;
var pipan_mouse_y;
 
document.onkeypress = pipan_onkeypress;
 
if(window.XMLHttpRequest) {
  ajax_pipan = new XMLHttpRequest();
}
else {
  ajax_pipan = new ActiveXObject("Microsoft.XMLHTTP");
}
ajax_pipan.onreadystatechange = ajax_pipan_done;
 
function ajax_pipan_done() {
  if(ajax_pipan.readyState == 4) {
    if(touch) {
      if((pan_bak != pan) || (tilt_bak != tilt)) {
        ajax_pipan_start();
      }
      else {
        setTimeout("ajax_pipan_done()", 100);
      }
    }
  }
}
 
function ajax_pipan_start () {
  ajax_pipan.open("GET","pipan.php?pan=" + pan + "&tilt=" + tilt, true);
  ajax_pipan.send();
  pan_bak = pan;
  tilt_bak = tilt;
}
 
function servo_left () {
  if(pan <= 190) pan += 10;
  ajax_pipan_start();
}
 
function servo_right () {
  if(pan >= 10) pan -= 10;
  ajax_pipan_start();
}
 
function servo_up () {
  if(tilt >= 10) tilt -= 10;
  ajax_pipan_start();
}
 
function servo_down () {
  if(tilt <= 190) tilt += 10;
  ajax_pipan_start();
}
 
function led_switch () {
 
  if(!led_stat) {
    led_stat = true;
    ajax_pipan.open("GET","pipan.php?red=" + document.getElementById("pilight_r").value + "&green=" + document.getElementById("pilight_g").value + "&blue=" + document.getElementById("pilight_b").value, true);
    ajax_pipan.send();
  }
  else {
    led_stat = false;
    ajax_pipan.open("GET","pipan.php?red=0&green=0&blue=0", true);
    ajax_pipan.send();
  }
 
}
 
function pipan_onkeypress (e) {
 
  if(e.keyCode == 97) servo_left();
  else if(e.keyCode == 119) servo_up();
  else if(e.keyCode == 100) servo_right();
  else if(e.keyCode == 115) servo_down();
  else if(e.keyCode == 102) led_switch();
 
}
 
function pipan_start () {
 
  pipan_mouse_x = null;
  pipan_mouse_y = null;
  pan_start = pan;
  tilt_start = tilt;
  document.body.addEventListener('touchmove', pipan_move, false)
  document.body.addEventListener('touchend', pipan_stop, false)
  touch = true;
  ajax_pipan_start();
 
}
 
function pipan_move (e) {
 
  var ev = e || window.event;
 
  if(pipan_mouse_x == null) {
    pipan_mouse_x = e.changedTouches[0].pageX;
    pipan_mouse_y = e.changedTouches[0].pageY;
  }
  mouse_x = e.changedTouches[0].pageX;
  mouse_y = e.changedTouches[0].pageY;
  e.preventDefault()
 
  var pan_temp = pan_start + Math.round((mouse_x-pipan_mouse_x)/5);
  var tilt_temp = tilt_start + Math.round((pipan_mouse_y-mouse_y)/5);
  if(pan_temp > 200) pan_temp = 200;
  if(pan_temp < 0) pan_temp = 0;
  if(tilt_temp > 200) tilt_temp = 200;
  if(tilt_temp < 0) tilt_temp = 0;
 
  pan = pan_temp;
  tilt = tilt_temp;
 
}
 
 
function pipan_stop () {
 
  document.body.removeEventListener('touchmove', pipan_move, false)
  document.body.removeEventListener('touchend', pipan_stop, false)
  touch = false;
 
  if(pipan_mouse_x == null) led_switch();
}

function init_pt(p,t){
   pan = p;
   tilt = 2*t-240;
}