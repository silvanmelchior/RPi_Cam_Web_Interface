<?php
   define('BASE_DIR', dirname(__FILE__));
   require_once(BASE_DIR.'/config.php');

   
   $pipe = fopen("FIFO","w");
   fwrite($pipe, $_GET["cmd"]);
   fclose($pipe);
?>
