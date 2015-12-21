There are 2 ways of installing the software ./RPi_Cam_Web_Interface_Installer.sh and a set of dedicated scripts.

The ./RPi_Cam_Web_Interface_Installer.sh is the original scheme largely developed under Wheezy.

The dedicated scripts are a re-factoring to simplify the process and these work under Wheezy and Jessie.
Future changes will be made to these.

5 scripts are used instead of combining all together.
This avoids the overhead of a separate selection and makes it easier to run a particular function automatically.
So start and stop can just be run as separate activities.

The scripts are
install.sh main installation
update.sh check for updates and then run main installation
start.sh starts the software
stop.sh stops the software
remove.sh removes the software

The main installation always does the same thing to simplify its logic.
It gathers all user parameters first in one combined dialog and then always
applies the parameters as it goes through the process.
A q (quiet) parameter may be used to skip this and give an automatic install based on config.txt
All parameters are always in the config.txt file, a default version is created if one
doesn't exist and is then changed just once after the initial user dialog.
The installation always tries to upgrade the main software components and then functionally goes through
the configuration steps for each area like apache, motion start up.

Debug is turned on for the moment so it logs its activity to a file called install.txt