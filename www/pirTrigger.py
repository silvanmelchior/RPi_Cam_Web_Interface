# This python program monitors a PIR sensor attached to a GPIO
# and then sends a motion start event to the scheduler
# The scheduler should be set up to perform a command in the Motion Start field
# Leave Motion Stop field blank
# Leave Motion detection disabled to use just the PIR trigger
# An example command would be ca 1 10 to do a 10 second video when PIR fires
# Script could be set up to start at boot (e.g. in /etc.rc.local
# Make sure to include an & 0n the end to ensure it starts in the background.
# An alternative is to write the command explicitly in fifo.write and use FIFO instead of FIFO1

import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
PIR_PIN = 14
GPIO.setup(PIR_PIN, GPIO.IN)

time.sleep(1)

try: 
  while True:
    if GPIO.input(PIR_PIN):
      fifo = open("/var/www/html/FIFO1", "w")
      fifo.write("1")
      fifo.close()
      while GPIO.input(PIR_PIN):
        time.sleep(1)
    time.sleep(1)
except KeyboardInterrupt:
  pass
finally:
  GPIO.cleanup()