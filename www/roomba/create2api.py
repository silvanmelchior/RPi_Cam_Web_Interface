        # The MIT License
#
# Copyright (c) 2007 Damon Kohler
# Copyright (c) 2015 Jonathan Le Roux (Modifications for Create 2)
# Copyright (c) 2015 Brandon Pomeroy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.




import json
import serial
import struct
import os
import warnings
import time


class Error(Exception):
    """Error"""
    pass

def custom_format_warning(message, category, filename, lineno, file=None, line=None):
    return 'Line ' + str(lineno) + ': ' + str(message) + '\n'
    #return ' %s:%s: %s:%s' % (filename, lineno, category.__name__, message)
    
class ROIDataByteError(Error):
    """Exception raised for errors in ROI data bytes.
    
        Attributes:
            msg -- explanation of the error
    """
    
    def __init__(self, msg):
        self.msg = msg

class ROIFailedToSendError(Error):
    """Exception raised when an error in data bytes prevented a packet to be sent
    
        Attributes:
            msg -- explanation of the error    
    """
    def __init__(self, msg):
        self.msg = msg

class ROIFailedToReceiveError(Error):
    """Exception raised when there is an error in the data received from the Create 2
        
        Attributes:
            msg -- explanation of the error
    """
    def __init__(self,msg):
        self.msg = msg


        
class Config(object):
    """This class handles loading and saving config files that store the
        Opcodes and other useful dicts
    
    """
    
    def __init__(self):
        self.fname = '/home/pi/roomba/config.json'
        self.data = None
    
    def load(self):
        """ Loads a Create2 config file, that holds various dicts of opcodes.
        
        """
        if os.path.isfile(self.fname):
            #file exists, load it
            with open(self.fname) as fileData:
                try:
                    self.data = json.load(fileData)
                    print 'Loaded config and opcodes'
                except ValueError, e:
                    print 'Could not load config'
        else:
            #couldn't find file
            print "No config file found"
            raise ValueError('Could not find config')
    
    

        
class SerialCommandInterface(object):
    """This class handles sending commands to the Create2.
    
    """

    def __init__(self):
        com = '/dev/ttyAMA0'  #This should not be hard coded...
        baud = 115200
        
        self.ser = serial.Serial()
        self.ser.port = com
        self.ser.baudrate = baud
        print self.ser.name
        if self.ser.isOpen(): 
            print "port was open"
            self.ser.close()
        self.ser.open()
        print "opened port"
    
    def send(self, opcode, data):
        #First thing to do is convert the opcode to a tuple.
        temp_opcode = (opcode,)
        bytes = None
        
        if data == None:
            #Sometimes opcodes don't need data. Since we can't add
            # a None type to a tuple, we have to make this check.
            bytes = temp_opcode
        else:
            #Add the opcodes and data together
            bytes = temp_opcode + data
        #print bytes
        self.ser.write(struct.pack('B' * len(bytes), *bytes))
    
    def Read(self, num_bytes):
        """Read a string of 'num_bytes' bytes from the robot.
        
            Arguments:
                num_bytes: The number of bytes we expect to read.
        """
        #logging.debug('Attempting to read %d bytes from SCI port.' % num_bytes)
        data = self.ser.read(num_bytes)
        #logging.debug('Read %d bytes from SCI port.' % len(data))
        if not data:
            raise ROIFailedToReceiveError('Error reading from SCI port. No data.')
        if len(data) != num_bytes:
            raise ROIFailedToReceiveError('Error reading from SCI port. Wrong data length.')
        return data
    
    def Close(self):
        """Closes the serial connection.
        """
        self.ser.close()

    
        
        
class Create2(object):
    """The top level class for controlling a Create2.
        This is the only class that outside scripts should be interacting with.    
    
    """
    
    def __init__(self):
        
        self.SCI = SerialCommandInterface()
        self.config = Config()
        self.config.load()
        self.decoder = sensorPacketDecoder(dict(self.config.data['sensor group packet lengths']))
        self.sensor_state = dict(self.config.data['sensor data']) # Load a raw sensor dict. None of these values are correct.
        self.sleep_timer = .5
        
    
    def destroy(self):
        """Closes up serial ports and terminates connection to the Create2
        """
        self.SCI.Close()
        print 'Disconnected'
    
    
    """ START OF OPEN INTERFACE COMMANDS
    """
    def start(self):
        self.SCI.send(self.config.data['opcodes']['start'], None)
        
    def reset(self):
        self.SCI.send(self.config.data['opcodes']['reset'], None)
        
    def stop(self):
        self.SCI.send(self.config.data['opcodes']['stop'], None)
        
    def baud(self, baudRate):
        baud_dict = {
            300:0,
            600:1,
            1200:2,
            2400:3,
            4800:4,
            9600:5,
            14400:6,
            19200:7,
            28800:8,
            38400:9,
            57600:10,
            115200:11
            }
        if baudRate in baud_dict:
            self.SCI.send(self.config.data['opcodes']['baud'], tuple(baud_dict[baudRate]))
        else:
            raise ROIDataByteError("Invalid buad rate")
    
    
    def safe(self):
        """Puts the Create 2 into safe mode. Blocks for a short (<.5 sec) amount of time so the
            bot has time to change modes.
        """
        self.SCI.send(self.config.data['opcodes']['safe'], None)
        time.sleep(self.sleep_timer)
    
    def full(self):
        """Puts the Create 2 into full mode. Blocks for a short (<.5 sec) amount of time so the
            bot has time to change modes.
        """
        self.SCI.send(self.config.data['opcodes']['full'], None)
        time.sleep(self.sleep_timer)
    
    def clean(self):
        self.SCI.send(self.config.data['opcodes']['clean'], None)
    
    def max(self):
        self.SCI.send(self.config.data['opcodes']['max'], None)
    
    def spot(self):
        self.SCI.send(self.config.data['opcodes']['spot'], None)
    
    def seek_dock(self):
        self.SCI.send(self.config.data['opcodes']['seek_dock'], None)
    
    def power(self):
        self.SCI.send(self.config.data['opcodes']['power'], None)
    
    def schedule(self):
        """Not implementing this for now.
        """    
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def set_day_time(self, day, hour, minute):
        """Sets the Create2's clock
            
            Args:
                day: A string describing the day.
                hour: A number from 0-23 (24 hour format)
                minute: A number from 0-59
        """
        data = [None, None, None]
        noError = True
        day = day.lower()
        
        day_dict = dict(
            sunday = 0,
            monday = 1,
            tuesday = 2,
            wednesday = 3,
            thursday = 4,
            friday = 5,
            saturday = 6
            )
        
        if day in day_dict:
            data[0] = day_dict[day]
        else:
            noError = False
            raise ROIDataByteError("Invalid day input")
        
        if hour >= 0 and hour <= 23:
            data[1] = hour
        else:
            noError = False
            raise ROIDataByteError("Invalid hour input")
        
        if minute >= 0 and minute <= 59:
            data[2] = minute
        else:
            noError = False
            raise ROIDataByteError("Invalid minute input")
            
        if noError:
            self.SCI.send(self.config.data['opcodes']['set_day_time'], tuple(data))
        else:
            raise ROIFailedToSendError("Invalid data, failed to send")
    
    def drive(self, velocity, radius): 
        """Controls the Create 2's drive wheels.
        
            Args:
                velocity: A number between -500 and 500. Units are mm/s. 
                radius: A number between -2000 and 2000. Units are mm.
                    Drive straight: 32767
                    Turn in place clockwise: -1
                    Turn in place counterclockwise: 1
        """
        noError = True
        data = []
        v = None
        r = None

        #Check to make sure we are getting sent valid velocity/radius.
        

        if velocity >= -500 and velocity <= 500:
            v = int(velocity) & 0xffff
            #Convert 16bit velocity to Hex
        else:
            noError = False
            raise ROIDataByteError("Invalid velocity input")
        
        if radius == 32767 or radius == -1 or radius == 1:
            #Special case radius
            r = int(radius) & 0xffff
            #Convert 16bit radius to Hex
        else:
            if radius >= -2000 and radius <= 2000:
                r = int(radius) & 0xffff
                #Convert 16bit radius to Hex
            else:
                noError = False
                raise ROIDataByteError("Invalid radius input")

        if noError:
            data = struct.unpack('4B', struct.pack('>2H', v, r))
            #An example of what data looks like:
            #print data >> (255, 56, 1, 244)
            
            #data[0] = Velocity high byte
            #data[1] = Velocity low byte
            #data[2] = Radius high byte
            #data[3] = Radius low byte
            
            #Normally we would convert data to a tuple before sending it to SCI
            #   But struct.unpack already returns a tuple.
            
            self.SCI.send(self.config.data['opcodes']['drive'], data)
        else:
            raise ROIFailedToSendError("Invalid data, failed to send")
        
    
    def drive_direct(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def drive_pwm(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def motors(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def motors_pwm(self, main_pwm, side_pwm, vacuum_pwm):
        """Serial sequence: [144] [Main Brush PWM] [Side Brush PWM] [Vacuum PWM] 
            
            Arguments:
                main_pwm: Duty cycle for Main Brush. Value from -127 to 127. Positive speeds spin inward.
                side_pwm: Duty cycle for Side Brush. Value from -127 to 127. Positive speeds spin counterclockwise.
                vacuum_pwm: Duty cycle for Vacuum. Value from 0-127. No negative speeds allowed.
        """
        noError = True
        data = []
        
        #First check that our data is within bounds
        if main_pwm >= -127 and main_pwm <= 127:
            data[0] = main_pwm
        else:
            noError = False
            raise ROIDataByteError("Invalid Main Brush input")
        if side_pwm >= -127 and side_pwm <= 127:
            data[1] = side_pwm
        else:
            noError = False
            raise ROIDataByteError("Invalid Side Brush input")
        if vacuum_pwm >= 0 and vacuum_pwm <= 127:
            data[2] = vacuum_pwm
        else:
            noError = False
            raise ROIDataByteError("Invalid Vacuum input")
        
        #Send it off if there were no errors.
        if noError:
            self.SCI.send(self.config.data['opcodes']['motors_pwm'], tuple(data))
        else:
            raise ROIFailedToSendError("Invalid data, failed to send")
        
    
    def led(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def scheduling_led(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def digit_led_raw(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def buttons(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def digit_led_ascii(self, display_string):
        """This command controls the four 7 segment displays using ASCII character codes.
        
            Arguments:
                display_string: A four character string to be displayed. This must be four
                    characters. Any blank characters should be represented with a space: ' '
                    Due to the limited display, there is no control over upper or lowercase
                    letters. create2api will automatically convert all chars to uppercase, but
                    some letters (Such as 'B' and 'D') will still display as lowercase on the
                    Create 2's display. C'est la vie.
        """
        noError = True
        display_string = display_string.upper()
        #print display_string
        if len(display_string) == 4:
            display_list = []
        else:
            #Too many or too few characters!
            noError = False
            raise ROIDataByteError("Invalid ASCII input (Must be EXACTLY four characters)")
        if noError:
            #Need to map ascii to numbers from the dict.
            for i in range (0,4):
                #Check that the character is in the list, if it is, add it.
                if display_string[i] in self.config.data['ascii table']:
                    display_list.append(self.config.data['ascii table'][display_string[i]])
                else:
                    # Char was not available. Just print a blank space
                    # Raise an error so the software knows that the input was bad
                    display_list.append(self.config.data['ascii table'][' '])
                    warnings.formatwarning = custom_format_warning
                    warnings.warn("Warning: Char '" + display_string[i] + "' was not found in ascii table")
                
            #print display_list
            self.SCI.send(self.config.data['opcodes']['digit_led_ascii'], tuple(display_list))
        else:
            raise ROIFailedToSendError("Invalid data, failed to send")
        
    
        
  #NOTE ABOUT SONGS: For some reason you cannot play a new song immediately after playing a different one, only the first song will play. You have to time.sleep() at least a fraction of a second for the speaker to process    
    def song(self):
        """Not implementing this for now.
        """
        #test sequence
        #self.SCI.send(self.config.data['opcodes']['start'],0)
        
    def play_test_sound(self):
        """written to figure out how to play sounds. creates a song with a playlist of notes and durations and then plays it through the speaker using a hilariously messy spread of concatenated lists
        """
        noError = True
        #sets lengths of notes
        short_note = 8
        medium_note = 16
        long_note = 20
        
        #stores a 4 note song in song 3
        current_song = 3
        song_length = 4
        song_setup = [current_song,song_length]
        play_list = []
        
        #writes the song note commands to play_list
        #change these to change notes
        play_list.extend([self.config.data['midi table']['C#4'],medium_note])
        play_list.extend([self.config.data['midi table']['G4'],long_note])
        play_list.extend([self.config.data['midi table']['A#3'],short_note])
        play_list.extend([self.config.data['midi table']['A3'],short_note])
        
        #adds up the various commands and arrays
        song_play = [self.config.data['opcodes']['play'], current_song]
        play_sequence = [song_setup + play_list + song_play]
        
        #flattens array
        play_sequence = [val for sublist in play_sequence for val in sublist]
        
        if noError:
            self.SCI.send(self.config.data['opcodes']['song'], tuple(play_sequence))
        else:
            raise ROIFailedToSendError("Invalid data, failed to send")
            
    

    def create_song(self,song_number,play_list):
        """create a new song from a playlist of notes and durations and tells the robot about it. Note: no error checking for playlist accuracy (must be a series of note opcodes and durations)
        """
        noError = True
        
        #the length of the song is the length of the array divided by 2
        song_setup = [song_number,len(play_list)/2]
        play_list = [song_setup + play_list]
        play_list = [val for sublist in play_list for val in sublist]

        if noError:   
            self.SCI.send(self.config.data['opcodes']['song'],tuple(play_list))
        else:
            raise ROIFailedToSendError("Invalid data, failed to send")

    def play(self,song_number):
        """Plays a stored song
        """
        noError = True

        if noError:
            self.SCI.send(self.config.data['opcodes']['play'], tuple([song_number]))
        else:
            raise ROIFailedToSendError("Invalid data, failed to send")
            
    def play_note(self,note_name,note_duration):
        """Plays a single note by creating a 1 note song in song 0
        """
        current_song = 0
        play_list=[]
        noError = True
        if noError:
            #Need to map ascii to numbers from the dict.

            if note_name in self.config.data['midi table']:
                play_list.append(self.config.data['midi table'][note_name])
                play_list.append(note_duration)
            else:
                # That note doesn't exist. Plays nothing
                # Raise an error so the software knows that the input was bad
                play_list.append(self.config.data['midi table'][0])
                warnings.formatwarning = custom_format_warning
                warnings.warn("Warning: Note '" + note_name + "' was not found in midi table")
            #create a song from play_list and play it
            self.create_song(current_song,play_list)
            self.play(current_song)
    
    def play_song(self,song_number,note_string):
        """
        Creates and plays a new song based off a string of notes and durations. 
        note_string - a string of notes,durations
        for example: 'G5,16,G3,16,A#4,30'
        """
        #splits the string of notes and durations into two lists
        split_list= note_string.split(',')
        note_list = split_list[0::2]
        duration_list = split_list[1::2]
        #creates a list for serial codes
        play_list = []
        #convert the durations to integers
        duration_list = map(int, duration_list)
        noError = True
        
        if noError:
            #Need to map midi to numbers from the dict.
            for i in range (0,len(note_list)):
                #Check that the note is in the list, if it is, add it.
                if note_list[i] in self.config.data['midi table']:
                    play_list.append(self.config.data['midi table'][note_list[i]])
                    play_list.append(duration_list[i])
                else:
                    # Note was not available. Play a rest
                    # Raise an error so the software knows that the input was bad
                    play_list.append(self.config.data['midi table']['rest'])
                    play_list.append(duration_list[i])
                    warnings.formatwarning = custom_format_warning
                    warnings.warn("Warning: Note '" + display_string[i] + "' was not found in midi table")
                
            #play the song
            self.create_song(song_number,play_list)
            self.play(song_number)
        else:
            raise ROIFailedToSendError("Invalid data, failed to send")
                
    def sensors(self, packet_id):
        """Requests the OI to send a packet of sensor data bytes.
        
            Arguments:
                packet_id: Identifies which of the 58 sensor data packets should be sent back by the OI. 
        """
        # Need to make sure the packet_id is a string
        packet_id = str(packet_id)
        # Check to make sure that the packet ID is valid.
        if packet_id in self.config.data['sensor group packet lengths']:
            # Valid packet, send request (But convert it back to an int in a list first)
            packet_id = [int(packet_id)]
            self.SCI.send(self.config.data['opcodes']['sensors'], tuple(packet_id))
        else:
            raise ROIFailedToSendError("Invalid packet id, failed to send")
        
    
    def query_list(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def stream(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)
    
    def pause_resume_stream(self):
        """Not implementing this for now.
        """
        #self.SCI.send(self.config.data['opcodes']['start'],0)

    """ END OF OPEN INTERFACE COMMANDS
    """
        
    def drive_straight(self, velocity):
        """ Will make the Create2 drive straight at the given velocity
        
            Arguments:
                velocity: Velocity of the Create2 in mm/s. Positive velocities are forward,
                    negative velocities are reverse. Max speeds are still enforced by drive()
        
        """
        self.drive(velocity, 32767)
        
    def turn_clockwise(self, velocity):
        """ Makes the Create2 turn in place clockwise at the given velocity
        
            Arguments:
                velocity: Velocity of the Create2 in mm/s. Positive velocities are forward,
                    negative velocities are reverse. Max speeds are still enforced by drive()
        """
        self.drive(velocity, -1)
        
    def turn_counter_clockwise(self, velocity):
        """ Makes the Create2 turn in place counter clockwise at the given velocity
    
            Arguments:
                velocity: Velocity of the Create2 in mm/s. Positive velocities are forward,
                    negative velocities are reverse. Max speeds are still enforced by drive()
        """
        self.drive(velocity, 1)
    
    def get_packet(self, packet_id):
        """ Requests and reads a packet from the Create 2
            
            Arguments:
                packet_id: The id of the packet you wish to collect.
            
            Returns: False if there was an error, True if the packet successfully came through.
        """
        packet_id = str(packet_id)
        packet_size = None
        packet_byte_data = None
        if packet_id in self.config.data['sensor group packet lengths']:
            # If a packet is in this dict, that means it is valid
            packet_size = self.config.data['sensor group packet lengths'][packet_id]
            #Let the robot know that we want some sensor data!
            self.sensors(packet_id)
            #Read the data
            packet_byte_data = list(self.SCI.Read(packet_size))
            # Once we have the byte data, we need to decode the packet and save the new sensor state
            self.sensor_state = self.decoder.decode_packet(packet_id, packet_byte_data, self.sensor_state)
            return True
        else:
            #The packet was invalid, raise an error
            raise ROIDataByteError("Invalid packet ID")
            return False



class sensorPacketDecoder(object):
    """ A class that handles sensor packet decoding. 
        
        This class may, in the future, become a private class. Users shouldn't be interacting with
        this class directly -- scripts should use Create2.get_packet() instead.
    
    """
    
    def __init__(self, sensor_packet_lengths):
        self.lengths = sensor_packet_lengths
    
    def decode_packet(self, packet_id, byte_data, sensor_data):
        """ Decodes an OI packet
            
            Arguments:
                packet_id: The id of the packet. Duh.
                byte_data: The bytes that the Create 2 sent over serial
                sensor_data: A dict containing the sensor states of the Create 2
            Returns:
                A dict containing the updated sensor states of the Create 2
        """
        return_dict = None
        id = int(packet_id)  # Convert the packet id from a string to an int
        
        # Depending on the packet id, we will need to do different decoding.
        # Packets 1-6 and 100, 101, 106, and 107 are special cases where they
        #   contain groups of packets.
        #
        # Other packets (7-58) are single packets, but some of them have two byte
        #   data, and also need special treatment.
        
        # Hold onto your hats. This is gonna get long fast.
        if id == 0:
            # Size 26, contains packet 7-26
            # We decode the data in reverse order to make pop() simpler
            sensor_data['battery capacity'] = self.decode_packet_26(byte_data.pop(), byte_data.pop())
            sensor_data['battery charge'] = self.decode_packet_25(byte_data.pop(), byte_data.pop())
            sensor_data['temperature'] = self.decode_packet_24(byte_data.pop())
            sensor_data['current'] = self.decode_packet_23(byte_data.pop(), byte_data.pop())
            sensor_data['voltage'] = self.decode_packet_22(byte_data.pop(), byte_data.pop())
            sensor_data['charging state'] = self.decode_packet_21(byte_data.pop())
            sensor_data['angle'] = self.decode_packet_20(byte_data.pop(), byte_data.pop())
            sensor_data['distance'] = self.decode_packet_19(byte_data.pop(), byte_data.pop())
            sensor_data['buttons'] = self.decode_packet_18(byte_data.pop())
            sensor_data['infared char omni'] = self.decode_packet_17(byte_data.pop())
            temp = self.decode_packet_16(byte_data.pop())
            sensor_data['dirt detect'] = self.decode_packet_15(byte_data.pop())
            sensor_data['wheel overcurrents'] = self.decode_packet_14(byte_data.pop())
            sensor_data['virtual wall'] = self.decode_packet_13(byte_data.pop())
            sensor_data['cliff right'] = self.decode_packet_12(byte_data.pop())
            sensor_data['cliff front right'] = self.decode_packet_11(byte_data.pop())
            sensor_data['cliff front left'] = self.decode_packet_10(byte_data.pop())
            sensor_data['cliff left'] = self.decode_packet_9(byte_data.pop())
            sensor_data['wall seen'] = self.decode_packet_8(byte_data.pop())
            sensor_data['wheel drop and bumps'] = self.decode_packet_7(byte_data.pop())
            
        elif id == 1:
            # Size 10, contains 7-16
            temp = self.decode_packet_16(byte_data.pop())
            sensor_data['dirt detect'] = self.decode_packet_15(byte_data.pop())
            sensor_data['wheel overcurrents'] = self.decode_packet_14(byte_data.pop())
            sensor_data['virtual wall'] = self.decode_packet_13(byte_data.pop())
            sensor_data['cliff right'] = self.decode_packet_12(byte_data.pop())
            sensor_data['cliff front right'] = self.decode_packet_11(byte_data.pop())
            sensor_data['cliff front left'] = self.decode_packet_10(byte_data.pop())
            sensor_data['cliff left'] = self.decode_packet_9(byte_data.pop())
            sensor_data['wall seen'] = self.decode_packet_8(byte_data.pop())
            sensor_data['wheel drop and bumps'] = self.decode_packet_7(byte_data.pop())
            
        elif id == 2:
            # size 6, contains 17-20
            sensor_data['angle'] = self.decode_packet_20(byte_data.pop(), byte_data.pop())
            sensor_data['distance'] = self.decode_packet_19(byte_data.pop(), byte_data.pop())
            sensor_data['buttons'] = self.decode_packet_18(byte_data.pop())
            sensor_data['infared char left'] = self.decode_packet_17(byte_data.pop())
            
        elif id == 3:
            # size 10, contains 21-26
            sensor_data['battery capacity'] = self.decode_packet_26(byte_data.pop(), byte_data.pop())
            sensor_data['battery charge'] = self.decode_packet_25(byte_data.pop(), byte_data.pop())
            sensor_data['temperature'] = self.decode_packet_24(byte_data.pop())
            sensor_data['current'] = self.decode_packet_23(byte_data.pop(), byte_data.pop())
            sensor_data['voltage'] = self.decode_packet_22(byte_data.pop(), byte_data.pop())
            sensor_data['charging state'] = self.decode_packet_21(byte_data.pop())
            
        elif id == 4:
            # size 14, contains 27-34
            sensor_data['charging sources available'] = self.decode_packet_34(byte_data.pop())
            temp1 = self.decode_packet_33(byte_data.pop(), byte_data.pop())
            temp = self.decode_packet_32(byte_data.pop())
            sensor_data['cliff right signal'] = self.decode_packet_31(byte_data.pop(), byte_data.pop())
            sensor_data['cliff front right signal'] = self.decode_packet_30(byte_data.pop(), byte_data.pop())
            sensor_data['cliff front left signal'] = self.decode_packet_29(byte_data.pop(), byte_data.pop())
            sensor_data['cliff left signal'] = self.decode_packet_28(byte_data.pop(), byte_data.pop())
            sensor_data['wall signal'] = self.decode_packet_27(byte_data.pop(), byte_data.pop())
            
        elif id == 5:
            # size 12, contains 35-42
            sensor_data['requested left velocity'] = self.decode_packet_42(byte_data.pop(), byte_data.pop())
            sensor_data['requested right velocity'] = self.decode_packet_41(byte_data.pop(), byte_data.pop())
            sensor_data['requested radius'] = self.decode_packet_40(byte_data.pop(), byte_data.pop())
            sensor_data['requested velocity'] = self.decode_packet_39(byte_data.pop(), byte_data.pop())
            sensor_data['number of stream packets'] = self.decode_packet_38(byte_data.pop())
            sensor_data['song playing'] = self.decode_packet_37(byte_data.pop())
            sensor_data['song number'] = self.decode_packet_36(byte_data.pop())
            sensor_data['oi mode'] = self.decode_packet_35(byte_data.pop())
            
        elif id == 6:
            # size 52, contains 7-42
            sensor_data['requested left velocity'] = self.decode_packet_42(byte_data.pop(), byte_data.pop())
            sensor_data['requested right velocity'] = self.decode_packet_41(byte_data.pop(), byte_data.pop())
            sensor_data['requested radius'] = self.decode_packet_40(byte_data.pop(), byte_data.pop())
            sensor_data['requested velocity'] = self.decode_packet_39(byte_data.pop(), byte_data.pop())
            sensor_data['number of stream packets'] = self.decode_packet_38(byte_data.pop())
            sensor_data['song playing'] = self.decode_packet_37(byte_data.pop())
            sensor_data['song number'] = self.decode_packet_36(byte_data.pop())
            sensor_data['oi mode'] = self.decode_packet_35(byte_data.pop())
            sensor_data['charging sources available'] = self.decode_packet_34(byte_data.pop())
            temp2 = self.decode_packet_33(byte_data.pop(), byte_data.pop())
            temp1 = self.decode_packet_32(byte_data.pop())
            sensor_data['cliff right signal'] = self.decode_packet_31(byte_data.pop(), byte_data.pop())
            sensor_data['cliff front right signal'] = self.decode_packet_30(byte_data.pop(), byte_data.pop())
            sensor_data['cliff front left signal'] = self.decode_packet_29(byte_data.pop(), byte_data.pop())
            sensor_data['cliff left signal'] = self.decode_packet_28(byte_data.pop(), byte_data.pop())
            sensor_data['wall signal'] = self.decode_packet_27(byte_data.pop(), byte_data.pop())
            sensor_data['battery capacity'] = self.decode_packet_26(byte_data.pop(), byte_data.pop())
            sensor_data['battery charge'] = self.decode_packet_25(byte_data.pop(), byte_data.pop())
            sensor_data['temperature'] = self.decode_packet_24(byte_data.pop())
            sensor_data['current'] = self.decode_packet_23(byte_data.pop(), byte_data.pop())
            sensor_data['voltage'] = self.decode_packet_22(byte_data.pop(), byte_data.pop())
            sensor_data['charging state'] = self.decode_packet_21(byte_data.pop())
            sensor_data['angle'] = self.decode_packet_20(byte_data.pop(), byte_data.pop())
            sensor_data['distance'] = self.decode_packet_19(byte_data.pop(), byte_data.pop())
            sensor_data['buttons'] = self.decode_packet_18(byte_data.pop())
            sensor_data['infared char omni'] = self.decode_packet_17(byte_data.pop())
            temp = self.decode_packet_16(byte_data.pop())
            sensor_data['dirt detect'] = self.decode_packet_15(byte_data.pop())
            sensor_data['wheel overcurrents'] = self.decode_packet_14(byte_data.pop())
            sensor_data['virtual wall'] = self.decode_packet_13(byte_data.pop())
            sensor_data['cliff right'] = self.decode_packet_12(byte_data.pop())
            sensor_data['cliff front right'] = self.decode_packet_11(byte_data.pop())
            sensor_data['cliff front left'] = self.decode_packet_10(byte_data.pop())
            sensor_data['cliff left'] = self.decode_packet_9(byte_data.pop())
            sensor_data['wall seen'] = self.decode_packet_8(byte_data.pop())
            sensor_data['wheel drop and bumps'] = self.decode_packet_7(byte_data.pop())
            
        elif id == 7:
            sensor_data['wheel drop and bumps'] = self.decode_packet_7(byte_data.pop())
        elif id == 8:
            sensor_data['wall seen'] = self.decode_packet_8(byte_data.pop())
        elif id == 9:
            sensor_data['cliff left'] = self.decode_packet_9(byte_data.pop())
        elif id == 10:
            sensor_data['cliff front left'] = self.decode_packet_10(byte_data.pop())
        elif id == 11:
            sensor_data['cliff front right'] = self.decode_packet_11(byte_data.pop())
        elif id == 12:
            sensor_data['cliff right'] = self.decode_packet_12(byte_data.pop())
        elif id == 13:
            sensor_data['virtual wall'] = self.decode_packet_13(byte_data.pop())
        elif id == 14:
            sensor_data['wheel overcurrents'] = self.decode_packet_14(byte_data.pop())
        elif id == 15:
            sensor_data['dirt detect'] = self.decode_packet_15(byte_data.pop())
        elif id == 16:
            #unused
            temp = self.decode_packet_16(byte_data.pop())
        elif id == 17:
            sensor_data['infared char omni'] = self.decode_packet_17(byte_data.pop())
        elif id == 18:
            sensor_data['buttons'] = self.decode_packet_18(byte_data.pop())
        elif id == 19:
            #2
            sensor_data['distance'] = self.decode_packet_19(byte_data.pop(), byte_data.pop())
        elif id == 20:
            #2
            sensor_data['angle'] = self.decode_packet_20(byte_data.pop(), byte_data.pop())
        elif id == 21:
            sensor_data['charging state'] = self.decode_packet_21(byte_data.pop())
        elif id == 22:
            #2
            sensor_data['voltage'] = self.decode_packet_22(byte_data.pop(), byte_data.pop())
        elif id == 23:
            #2
            sensor_data['current'] = self.decode_packet_23(byte_data.pop(), byte_data.pop())
        elif id == 24:
            sensor_data['temperature'] = self.decode_packet_24(byte_data.pop())
        elif id == 25:
            #2
            sensor_data['battery charge'] = self.decode_packet_25(byte_data.pop(), byte_data.pop())
        elif id == 26:
            #2
            sensor_data['battery capacity'] = self.decode_packet_26(byte_data.pop(), byte_data.pop())
        elif id == 27:
            #2
            sensor_data['wall signal'] = self.decode_packet_27(byte_data.pop(), byte_data.pop())
        elif id == 28:
            #2
            sensor_data['cliff left signal'] = self.decode_packet_28(byte_data.pop(), byte_data.pop())
        elif id == 29:
            #2
            sensor_data['cliff front left signal'] = self.decode_packet_29(byte_data.pop(), byte_data.pop())
        elif id == 30:
            #2
            sensor_data['cliff front right signal'] = self.decode_packet_30(byte_data.pop(), byte_data.pop())
        elif id == 31:
            #2
            sensor_data['cliff right signal'] = self.decode_packet_31(byte_data.pop(), byte_data.pop())
        elif id == 32:
            temp = self.decode_packet_32(byte_data.pop())
        elif id == 33:
            #2
            temp = self.decode_packet_33(byte_data.pop(), byte_data.pop())
        elif id == 34:
            sensor_data['charging sources available'] = self.decode_packet_34(byte_data.pop())
        elif id == 35:
            sensor_data['oi mode'] = self.decode_packet_35(byte_data.pop())
        elif id == 36:
            sensor_data['song number'] = self.decode_packet_36(byte_data.pop())
        elif id == 37:
            sensor_data['song playing'] = self.decode_packet_37(byte_data.pop())
        elif id == 38:
            sensor_data['number of stream packets'] = self.decode_packet_38(byte_data.pop())
        elif id == 39:
            #2
            sensor_data['requested velocity'] = self.decode_packet_39(byte_data.pop(), byte_data.pop())
        elif id == 40:
            #2
            sensor_data['requested radius'] = self.decode_packet_40(byte_data.pop(), byte_data.pop())
        elif id == 41:
            #2
            sensor_data['requested right velocity'] = self.decode_packet_41(byte_data.pop(), byte_data.pop())
        elif id == 42:
            #2
            sensor_data['requested left velocity'] = self.decode_packet_42(byte_data.pop(), byte_data.pop())
        elif id == 43:
            #2
            sensor_data['left encoder counts'] = self.decode_packet_43(byte_data.pop(), byte_data.pop())
        elif id == 44:
            #2
            sensor_data['right encoder counts'] = self.decode_packet_44(byte_data.pop(), byte_data.pop())
        elif id == 45:
            sensor_data['light bumper'] = self.decode_packet_45(byte_data.pop())
        elif id == 46:
            #2
            sensor_data['light bump left signal'] = self.decode_packet_46(byte_data.pop(), byte_data.pop())
        elif id == 47:
            #2
            sensor_data['light bump front left signal'] = self.decode_packet_47(byte_data.pop(), byte_data.pop())
        elif id == 48:
            #2
            sensor_data['light bump center left signal'] = self.decode_packet_48(byte_data.pop(), byte_data.pop())
        elif id == 49:
            #2
            sensor_data['light bump center right signal'] = self.decode_packet_49(byte_data.pop(), byte_data.pop())
        elif id == 50:
            #2
            sensor_data['light bump front right signal'] = self.decode_packet_50(byte_data.pop(), byte_data.pop())
        elif id == 51:
            #2
            sensor_data['light bump right signal'] = self.decode_packet_51(byte_data.pop(), byte_data.pop())
        elif id == 52:
            sensor_data['infared char left'] = self.decode_packet_52(byte_data.pop())
        elif id == 53:
            sensor_data['infared char right'] = self.decode_packet_53(byte_data.pop())
        elif id == 54:
            #2
            sensor_data['left motor current'] = self.decode_packet_54(byte_data.pop(), byte_data.pop())
        elif id == 55:
            #2
            sensor_data['right motor current'] = self.decode_packet_55(byte_data.pop(), byte_data.pop())
        elif id == 56:
            #2
            sensor_data['main brush motor current'] = self.decode_packet_56(byte_data.pop(), byte_data.pop())
        elif id == 57:
            #2
            sensor_data['side brush motor current'] = self.decode_packet_57(byte_data.pop(), byte_data.pop())
        elif id == 58:
            sensor_data['stasis'] = self.decode_packet_58(byte_data.pop())
            ##### Single Packets END
        elif id == 100:
            # size 80, contains 7-58 (ALL)
            sensor_data['stasis'] = self.decode_packet_58(byte_data.pop())
            sensor_data['side brush motor current'] = self.decode_packet_57(byte_data.pop(), byte_data.pop())
            sensor_data['main brush motor current'] = self.decode_packet_56(byte_data.pop(), byte_data.pop())
            sensor_data['right motor current'] = self.decode_packet_55(byte_data.pop(), byte_data.pop())
            sensor_data['left motor current'] = self.decode_packet_54(byte_data.pop(), byte_data.pop())
            sensor_data['infared char right'] = self.decode_packet_53(byte_data.pop())
            sensor_data['infared char left'] = self.decode_packet_52(byte_data.pop())
            sensor_data['light bump right signal'] = self.decode_packet_51(byte_data.pop(), byte_data.pop())
            sensor_data['light bump front right signal'] = self.decode_packet_50(byte_data.pop(), byte_data.pop())
            sensor_data['light bump center right signal'] = self.decode_packet_49(byte_data.pop(), byte_data.pop())
            sensor_data['light bump center left signal'] = self.decode_packet_48(byte_data.pop(), byte_data.pop())
            sensor_data['light bump front left signal'] = self.decode_packet_47(byte_data.pop(), byte_data.pop())
            sensor_data['light bump left signal'] = self.decode_packet_46(byte_data.pop(), byte_data.pop())
            sensor_data['light bumper'] = self.decode_packet_45(byte_data.pop())
            sensor_data['right encoder counts'] = self.decode_packet_44(byte_data.pop(), byte_data.pop())
            sensor_data['left encoder counts'] = self.decode_packet_43(byte_data.pop(), byte_data.pop())
            sensor_data['requested left velocity'] = self.decode_packet_42(byte_data.pop(), byte_data.pop())
            sensor_data['requested right velocity'] = self.decode_packet_41(byte_data.pop(), byte_data.pop())
            sensor_data['requested radius'] = self.decode_packet_40(byte_data.pop(), byte_data.pop())
            sensor_data['requested velocity'] = self.decode_packet_39(byte_data.pop(), byte_data.pop())
            sensor_data['number of stream packets'] = self.decode_packet_38(byte_data.pop())
            sensor_data['song playing'] = self.decode_packet_37(byte_data.pop())
            sensor_data['song number'] = self.decode_packet_36(byte_data.pop())
            sensor_data['oi mode'] = self.decode_packet_35(byte_data.pop())
            sensor_data['charging sources available'] = self.decode_packet_34(byte_data.pop())
            temp2 = self.decode_packet_33(byte_data.pop(), byte_data.pop())
            temp1 = self.decode_packet_32(byte_data.pop())
            sensor_data['cliff right signal'] = self.decode_packet_31(byte_data.pop(), byte_data.pop())
            sensor_data['cliff front right signal'] = self.decode_packet_30(byte_data.pop(), byte_data.pop())
            sensor_data['cliff front left signal'] = self.decode_packet_29(byte_data.pop(), byte_data.pop())
            sensor_data['cliff left signal'] = self.decode_packet_28(byte_data.pop(), byte_data.pop())
            sensor_data['wall signal'] = self.decode_packet_27(byte_data.pop(), byte_data.pop())
            sensor_data['battery capacity'] = self.decode_packet_26(byte_data.pop(), byte_data.pop())
            sensor_data['battery charge'] = self.decode_packet_25(byte_data.pop(), byte_data.pop())
            sensor_data['temperature'] = self.decode_packet_24(byte_data.pop())
            sensor_data['current'] = self.decode_packet_23(byte_data.pop(), byte_data.pop())
            sensor_data['voltage'] = self.decode_packet_22(byte_data.pop(), byte_data.pop())
            sensor_data['charging state'] = self.decode_packet_21(byte_data.pop())
            sensor_data['angle'] = self.decode_packet_20(byte_data.pop(), byte_data.pop())
            sensor_data['distance'] = self.decode_packet_19(byte_data.pop(), byte_data.pop())
            sensor_data['buttons'] = self.decode_packet_18(byte_data.pop())
            sensor_data['infared char omni'] = self.decode_packet_17(byte_data.pop())
            temp = self.decode_packet_16(byte_data.pop())
            sensor_data['dirt detect'] = self.decode_packet_15(byte_data.pop())
            sensor_data['wheel overcurrents'] = self.decode_packet_14(byte_data.pop())
            sensor_data['virtual wall'] = self.decode_packet_13(byte_data.pop())
            sensor_data['cliff right'] = self.decode_packet_12(byte_data.pop())
            sensor_data['cliff front right'] = self.decode_packet_11(byte_data.pop())
            sensor_data['cliff front left'] = self.decode_packet_10(byte_data.pop())
            sensor_data['cliff left'] = self.decode_packet_9(byte_data.pop())
            sensor_data['wall seen'] = self.decode_packet_8(byte_data.pop())
            sensor_data['wheel drop and bumps'] = self.decode_packet_7(byte_data.pop())
            
        elif id == 101:
            # size 28, contains 43-58
            sensor_data['stasis'] = self.decode_packet_58(byte_data.pop())
            sensor_data['side brush motor current'] = self.decode_packet_57(byte_data.pop(), byte_data.pop())
            sensor_data['main brush motor current'] = self.decode_packet_56(byte_data.pop(), byte_data.pop())
            sensor_data['right motor current'] = self.decode_packet_55(byte_data.pop(), byte_data.pop())
            sensor_data['left motor current'] = self.decode_packet_54(byte_data.pop(), byte_data.pop())
            sensor_data['infared char right'] = self.decode_packet_53(byte_data.pop())
            sensor_data['infared char left'] = self.decode_packet_52(byte_data.pop())
            sensor_data['light bump right signal'] = self.decode_packet_51(byte_data.pop(), byte_data.pop())
            sensor_data['light bump front right signal'] = self.decode_packet_50(byte_data.pop(), byte_data.pop())
            sensor_data['light bump center right signal'] = self.decode_packet_49(byte_data.pop(), byte_data.pop())
            sensor_data['light bump center left signal'] = self.decode_packet_48(byte_data.pop(), byte_data.pop())
            sensor_data['light bump front left signal'] = self.decode_packet_47(byte_data.pop(), byte_data.pop())
            sensor_data['light bump left signal'] = self.decode_packet_46(byte_data.pop(), byte_data.pop())
            sensor_data['light bumper'] = self.decode_packet_45(byte_data.pop())
            sensor_data['right encoder counts'] = self.decode_packet_44(byte_data.pop(), byte_data.pop())
            sensor_data['left encoder counts'] = self.decode_packet_43(byte_data.pop(), byte_data.pop())
            
        elif id == 106:
            # size 12, contains 46-51
            sensor_data['light bump right signal'] = self.decode_packet_51(byte_data.pop(), byte_data.pop())
            sensor_data['light bump front right signal'] = self.decode_packet_50(byte_data.pop(), byte_data.pop())
            sensor_data['light bump center right signal'] = self.decode_packet_49(byte_data.pop(), byte_data.pop())
            sensor_data['light bump center left signal'] = self.decode_packet_48(byte_data.pop(), byte_data.pop())
            sensor_data['light bump front left signal'] = self.decode_packet_47(byte_data.pop(), byte_data.pop())
            sensor_data['light bump left signal'] = self.decode_packet_46(byte_data.pop(), byte_data.pop())
            
        elif id == 107:
            # size 9, contains 54-58
            sensor_data['stasis'] = self.decode_packet_58(byte_data.pop())
            sensor_data['side brush motor current'] = self.decode_packet_57(byte_data.pop(), byte_data.pop())
            sensor_data['main brush motor current'] = self.decode_packet_56(byte_data.pop(), byte_data.pop())
            sensor_data['right motor current'] = self.decode_packet_55(byte_data.pop(), byte_data.pop())
            sensor_data['left motor current'] = self.decode_packet_54(byte_data.pop(), byte_data.pop())
            
        else:
            warnings.formatwarning = custom_format_warning
            warnings.warn("Warning: Packet '" + id + "' is not a valid packet!")
            
        
        # No, Python doesn't need a switch case at all.
        
        return sensor_data
        
    def decode_packet_7(self, data):
        """ Decode Packet 7 (wheel drop and bumps) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: A dict of 'wheel drop and bumps'
        """
        byte = struct.unpack('B', data)[0]
        return_dict = {
            'drop left': bool(byte & 0x08),
            'drop right': bool(byte & 0x04),
            'bump left': bool(byte & 0x02),
            'bump right': bool(byte & 0x01)}
        return return_dict

    def decode_packet_8(self, data):
        """ Decode Packet 8 (wall seen) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: True or False
        """
        return self.decode_bool(data)

    def decode_packet_9(self, data):
        """ Decode Packet 9 (cliff left) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: True or False
        """
        return self.decode_bool(data)   

    def decode_packet_10(self, data):
        """ Decode Packet 10 (cliff front left) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: True or False
        """
        return self.decode_bool(data)

    def decode_packet_11(self, data):
        """ Decode Packet 11 (cliff front right) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: True or False
        """
        return self.decode_bool(data)

    def decode_packet_12(self, data):
        """ Decode Packet 12 (cliff right) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: True or False
        """
        return self.decode_bool(data)

    def decode_packet_13(self, data):
        """ Decode Packet 13 (virtual wall) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: True or False
        """
        return self.decode_bool(data)
        
    def decode_packet_14(self, data):
        """ Decode Packet 14 (wheel overcurrents) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: A dict of 'wheel overcurrents'
        """
        byte = struct.unpack('B', data)[0]
        return_dict = {
            'left wheel': bool(byte & 0x10),
            'right wheel': bool(byte & 0x08),
            'main brush': bool(byte & 0x04),
            'side brush': bool(byte & 0x01)}
        return return_dict
        
    def decode_packet_15(self, data):
        """ Decode Packet 15 (dirt detect) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: unsigned Byte (0-255)
        """
        return self.decode_unsigned_byte(data)        

    def decode_packet_16(self, data):
        """ Decode Packet 16 (unused byte) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: None
        """
        return None  

    def decode_packet_17(self, data):
        """ Decode Packet 17 (infared char omni) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: unsigned Byte (0-255)
        """
        return self.decode_unsigned_byte(data)

    def decode_packet_18(self, data):
        """ Decode Packet 18 (buttons) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: a dict of 'buttons'
        """
        byte = struct.unpack('B', data)[0]
        return_dict = {
            'clock': bool(byte & 0x80),
            'schedule': bool(byte & 0x40),
            'day': bool(byte & 0x20),
            'hour': bool(byte & 0x10),
            'minute': bool(byte & 0x08),
            'dock': bool(byte & 0x04),
            'spot': bool(byte & 0x02),
            'clean': bool(byte & 0x01)}
        
        return return_dict

    def decode_packet_19(self, low, high):
        """ Decode Packet 19 (distance) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: signed 16bit short
        """
        return self.decode_short(low, high)

    def decode_packet_20(self, low, high):
        """ Decode Packet 20 (angle) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: signed 16 bit short. Represents difference between distance two wheels travelled
        """
        return self.decode_short(low, high)
        
    def decode_packet_21(self, data):
        """ Decode Packet 21 (charging state) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: A value from 0-5, that describes the charging state
        """
        return self.decode_unsigned_byte(data)

    def decode_packet_22(self, low, high):
        """ Decode Packet 22 (voltage) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short, battery voltage in mV
        """
        return self.decode_unsigned_short(low, high)

    def decode_packet_23(self, low, high):
        """ Decode Packet 23 (current) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: signed 16bit short. Positive currents is charging, negative is discharging
        """
        return self.decode_short(low, high)
        
    def decode_packet_24(self, data):
        """ Decode Packet 24 (temperature) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: A signed byte, Create 2's battery temperature in Celsius
        """
        return self.decode_byte(data)
        
    def decode_packet_25(self, low, high):
        """ Decode Packet 25 (battery charge) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Current charge of battery in milliAmp-hours
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_26(self, low, high):
        """ Decode Packet 26 (battery capacity) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Estimated charge capacity of battery in milliAmp-hours
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_27(self, low, high):
        """ Decode Packet 27 (wall signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of wall signal from 0-1023
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_28(self, low, high):
        """ Decode Packet 28 (cliff left signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of cliff left signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_29(self, low, high):
        """ Decode Packet 29 (cliff front left signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of cliff front left signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_30(self, low, high):
        """ Decode Packet 30 (cliff front right signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of cliff front right signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_31(self, low, high):
        """ Decode Packet 31 (cliff right signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of cliff right signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_32(self, data):
        """ Decode Packet 32 (Unused) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: None
        """
        return None
        
    def decode_packet_33(self, low, high):
        """ Decode Packet 33 (Unused) and return its value
        
            Arguments:
                low: The bytes to ignore
                high: The bytes to ignore
        
            Returns: None
        """
        return None
        
    def decode_packet_34(self, data):
        """ Decode Packet 34 (charging sources available) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: A dict of 'charging sources available'
        """
        byte = struct.unpack('B', data)[0]
        return_dict = {
            'home base': bool(byte & 0x02),
            'internal charger': bool(byte & 0x01)}
        
        return return_dict

    def decode_packet_35(self, data):
        """ Decode Packet 35 (OI Mode) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: A unsigned byte, the current OI mode id from 0-3
        """
        return self.decode_unsigned_byte(data)
        
    def decode_packet_36(self, data):
        """ Decode Packet 36 (Song number) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: An unsigned byte, the current song id playing (0-15)
        """
        return self.decode_unsigned_byte(data)
        
    def decode_packet_37(self, data):
        """ Decode Packet 35 (Song playing) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: True or False, stating whether the song is playing
        """
        return self.decode_bool(data)
        
    def decode_packet_38(self, data):
        """ Decode Packet 38 (Number of stream packets) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: An unsigned byte, the number of data stream packets
        """
        return self.decode_unsigned_byte(data)
        
    def decode_packet_39(self, low, high):
        """ Decode Packet 39 (requested velocity) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Velocity most recently requested by Drive()
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_40(self, low, high):
        """ Decode Packet 40 (requested radius) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Radius most recently requested by Drive()
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_41(self, low, high):
        """ Decode Packet 41 (Requested right velocity) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Right wheel velocity recently requested by DriveDirect()
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_42(self, low, high):
        """ Decode Packet 42 (Requested left velocity) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Left wheel velocity recently requested by DriveDirect()
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_43(self, low, high):
        """ Decode Packet 41 (Left Encoder Counts) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Cumulative number of raw left encoder counts. Rolls over
                        to 0 after it passes 65535
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_44(self, low, high):
        """ Decode Packet 44 (Right Encoder Counts) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Cumulative number of raw right encoder counts. Rolls over
                        to 0 after it passes 65535
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_45(self, data):
        """ Decode Packet 45 (infared char left) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: A dict of 'light bumper'
        """
        byte = struct.unpack('B', data)[0]
        return_dict = {
            'right': bool(byte & 0x20),
            'front right': bool(byte & 0x10),
            'center right': bool(byte & 0x08),
            'center left': bool(byte & 0x04),
            'front left': bool(byte & 0x02),
            'left': bool(byte & 0x01)}
        return return_dict

    def decode_packet_46(self, low, high):
        """ Decode Packet 46 (Light Bump Left Signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of light bump left signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_47(self, low, high):
        """ Decode Packet 47 (Light Bump Front Left Signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of light bump front left signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_48(self, low, high):
        """ Decode Packet 48 (Light Bump Center Left Signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of light bump center left signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_49(self, low, high):
        """ Decode Packet 49 (Light Bump Center Right Signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of light bump center right signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_50(self, low, high):
        """ Decode Packet 50 (Light Bump Front Right Signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of light bump front right signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_51(self, low, high):
        """ Decode Packet 51 (Light Bump Right Signal) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: unsigned 16bit short. Strength of light bump right signal from 0-4095
        """
        return self.decode_unsigned_short(low, high)
        
    def decode_packet_52(self, data):
        """ Decode Packet 52 (infared char left) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: unsigned Byte (0-255)
        """
        return self.decode_unsigned_byte(data)          

    def decode_packet_53(self, data):
        """ Decode Packet 53 (infared char right) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: unsigned Byte (0-255)
        """
        return self.decode_unsigned_byte(data)  

    def decode_packet_54(self, low, high):
        """ Decode Packet 54 (Left Motor Current) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: signed 16bit short. Strength of left motor current from -32768 - 32767 mA
        """
        return self.decode_short(low, high)
        

    def decode_packet_55(self, low, high):
        """ Decode Packet 55 (Right Motor Current) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: signed 16bit short. Strength of right motor current from -32768 - 32767 mA
        """
        return self.decode_short(low, high)
        

    def decode_packet_56(self, low, high):
        """ Decode Packet 54 (Main Brush Motor Current) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: signed 16bit short. Strength of main brush motor current from -32768 - 32767 mA
        """
        return self.decode_short(low, high)
        

    def decode_packet_57(self, low, high):
        """ Decode Packet 57 (Side Brush Motor Current) and return its value
        
            Arguments:
                low: Low byte of the 2's complement. Low is specified first to make pop() easier
                high: High byte of the 2's complement
        
            Returns: signed 16bit short. Strength of side brush motor current from -32768 - 32767 mA
        """
        return self.decode_short(low, high)
        
    def decode_packet_58(self, data):
        """ Decode Packet 58 (Stasis) and return its value
        
            Arguments:
                data: The bytes to decode
        
            Returns: True if robot is making forward progress, else False
        """
        return self.decode_bool(data)  

        
    def decode_bool(self, byte):
        """ Decode a byte and return the value
        
            Arguments:
                byte: The byte to be decoded
            Returns: True or False
        """
        return bool(struct.unpack('B', byte)[0])
    

    def decode_unsigned_short(self, low, high):
        """ Decode an 16 bit unsigned short from two bytes. 
        
            Arguments:
                low: The low byte of the 2's complement. This is specified first
                    to make it easier when popping bytes off a list.
                high: The high byte o the 2's complement.
            Returns: 16bit unsigned short
        """
        return struct.unpack('>H', high + low)[0]
        
    def decode_short(self, low, high):
        """ Decode an 16 bit short from two bytes. 
        
            Arguments:
                low: The low byte of the 2's complement. This is specified first
                    to make it easier when popping bytes off a list.
                high: The high byte of the 2's complement.
            Returns: 16bit short
        """
        return struct.unpack('>h', high + low)[0]
        
    def decode_byte(self, byte):
        """ Decode a signed byte into a signed char 
        
            Arguments:
                byte: The byte to be decoded
            Returns: A signed int
        """
        return struct.unpack('b', byte)[0]
    
    def decode_unsigned_byte(self, byte):
        """ Decode an unsigned byte into an unsigned char 
        
            Arguments:
                byte: The byte to be decoded
            Returns: An unsigned int
        """
        return struct.unpack('B', byte)[0]
