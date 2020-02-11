import create2api
import RPi.GPIO as GPIO
from time import sleep
from sys import argv

#Driving control:
def forward():
    bot = create2api.Create2()
    bot.drive_straight(110)

def left():
    bot = create2api.Create2()
    bot.turn_clockwise(-11)

def stop():
    bot = create2api.Create2()
    bot.drive_straight(0)
	
def right():
    bot = create2api.Create2()
    bot.turn_clockwise(11)

def backward():
    bot = create2api.Create2()
    bot.drive_straight(-110)

#Driving mode:
def open():
    bot = create2api.Create2()
    bot.start()
    bot.safe()

def close():
    bot = create2api.Create2()
    bot.stop()

#Camera position:
def camera_0():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(18, GPIO.OUT)
    servo = GPIO.PWM(18, 50)
    servo.start(0)
    servo.ChangeDutyCycle(2 + (90 / 18))
    sleep(0.5)
    servo.ChangeDutyCycle(0)
    servo.stop()
    GPIO.cleanup()

def camera_30():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(18, GPIO.OUT)
    servo = GPIO.PWM(18, 50)
    servo.start(0)
    servo.ChangeDutyCycle(2 + (60 / 18))
    sleep(0.5)
    servo.ChangeDutyCycle(0)
    servo.stop()
    GPIO.cleanup()

def camera_60():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(18, GPIO.OUT)
    servo = GPIO.PWM(18, 50)
    servo.start(0)
    servo.ChangeDutyCycle(2 + (30 / 18))
    sleep(0.5)
    servo.ChangeDutyCycle(0)
    servo.stop()
    GPIO.cleanup()

def camera_90():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(18, GPIO.OUT)
    servo = GPIO.PWM(18, 50)
    servo.start(0)
    servo.ChangeDutyCycle(2 + (0 / 18))
    sleep(0.5)
    servo.ChangeDutyCycle(0)
    servo.stop()
    GPIO.cleanup()

#Basic controls:
def wake_up():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(23, GPIO.OUT)
    GPIO.output(23, GPIO.HIGH)
    sleep(1)
    GPIO.output(23, GPIO.LOW)
    sleep(1)
    GPIO.output(23, GPIO.HIGH)
    GPIO.cleanup()

def stand_by():
    bot = create2api.Create2()
    bot.start()
    bot.power()
    bot.stop()

def clean():
    bot = create2api.Create2()
    bot.start()
    bot.clean()
    bot.stop()

def spot():
    bot = create2api.Create2()
    bot.start()
    bot.spot()
    bot.stop()

def dock():
    bot = create2api.Create2()
    bot.start()
    bot.seek_dock()
    bot.stop()

_, function_name = argv
locals()[function_name]()
