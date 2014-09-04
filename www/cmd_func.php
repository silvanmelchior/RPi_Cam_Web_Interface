<?php
  
  function sys_cmd($cmd) {
    if(strncmp($cmd, "reboot", strlen("reboot")) == 0) {
      shell_exec('sudo shutdown -r now');
    } else if(strncmp($cmd, "shutdown", strlen("reboot")) == 0) {
      shell_exec('sudo shutdown -h now');
    } else {
      // unknown
    }
  }


  if(isset($_GET['cmd'])) {
    $cmd=$_GET['cmd'];
    sys_cmd($cmd);
  }

?>
