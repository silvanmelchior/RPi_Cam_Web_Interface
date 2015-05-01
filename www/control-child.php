<!DOCTYPE html>
   
<html>
<body>

<?php
if ($_GET['right']) {
  # This code will run if ?run=true is set.

exec('sh /var/www/right.sh');
}
?>

<?php
if ($_GET['left']) {
  # This code will run if ?run=true is set.
  exec('sh /var/www/left.sh');
}
?>

<?php
if ($_GET['up']) {
  # This code will run if ?run=true is set.
  exec('sh /var/www/up.sh');
}
?>

<?php
if ($_GET['down']) {
  # This code will run if ?run=true is set.
  exec('sh /var/www/down.sh');
}
?>


<!-- This link will add ?run=true to your URL, myfilename.php?run=true -->
<a href="?up=true"><center><img src="up.jpg" alt="Up" style="width:50px;height:50px"></center></a>

<!-- This link will add ?run=true to your URL, myfilename.php?run=true -->
<center><a href="?left=true"><img src="left.jpg" alt="Left" style="width:50px;height:50px"></a>

 &nbsp  &nbsp  &nbsp  &nbsp  &nbsp

<!-- This link will add ?run=true to your URL, myfilename.php?run=true -->
<a href="?right=true"><img src="right.jpg" alt="Right" style="width:50px;height:50px"></a></center>

<!-- This link will add ?run=true to your URL, myfilename.php?run=true -->
<a href="?down=true"><center><img src="down.jpg" alt="Down" style="width:50px;height:50px"></center></a>

   </body>
</html>

