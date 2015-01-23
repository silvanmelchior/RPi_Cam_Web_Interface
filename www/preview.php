<!DOCTYPE html>
<html>
  <head>
    <title>RPi Cam Download</title>
  </head>
  <body>
    <p><a href="index.php">Back</a></p>
    <?php
      if(isset($_GET["delete"])) {
        unlink("media/" . $_GET["delete"]);
      }
      if(isset($_GET["delete_all"])) {
        $files = scandir("media");
        foreach($files as $file) unlink("media/$file");
      }
      else if(isset($_GET["file"])) {
        echo "<h1>Preview</h1>";
        if(substr($_GET["file"], -3) == "jpg") echo "<a href='media/" . $_GET["file"] . "' target='_blank'><img src='media/" . $_GET["file"] . "' width='640'></a>";
        else echo "<video width='640' controls><source src='media/" . $_GET["file"] . "' type='video/mp4'>Your browser does not support the video tag.</video>";
        echo "<p><input type='button' value='Download' onclick='window.open(\"download.php?file=" . $_GET["file"] . "\", \"_blank\");'> ";
        echo "<input type='button' value='Delete' onclick='window.location=\"preview.php?delete=" . $_GET["file"] . "\";'></p>";
      }
    ?>
    <h1>Files</h1>
    <?php
      $files = scandir("media");
      if(count($files) == 2) echo "<p>No videos/images saved</p>";
      else {
        foreach($files as $file) {
          if(($file != '.') && ($file != '..')) {
            $fsz = round ((filesize("media/" . $file)) / (1024 * 1024));
            echo "<p><a href='preview.php?file=$file'>$file</a> ($fsz MB) ";
            echo "<input type='button' value='Delete' onclick='if(confirm(\"Delete $file?\")) {window.location=\"preview.php?delete=$file\";}'></p>";
          }
        }
        echo "<p><input type='button' value='Delete all' onclick='if(confirm(\"Delete all?\")) {window.location=\"preview.php?delete_all\";}'></p>";
      }
    ?>
  </body>
</html>
