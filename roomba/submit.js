function runCommand(event) {
    var command = event.target.name;
    $.post("roomba/command.php", {command: command},
        function () {

        });
}
