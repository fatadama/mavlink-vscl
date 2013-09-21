import sys, os, time

#sys.path.insert(0,os.path.join(os.path.dirname(os.path.realpath(__file__)),'..'))
sys.path.insert(0,os.path.join(os.path.dirname(os.path.realpath("fake_mav_test.py")),'..'))

import mavlinkv10 as mavlink, mavutil

#com port options
port = "COM10"
baudr = 57600

master = mavutil.mavlink_connection(port,baud=baudr)

i = 0

tLast = -10;

while i<1e5:
    i+=1
    time.sleep(.25)
    if (time.clock()-tLast)>1.0:
        master.mav.heartbeat_send(1,3,64,0,0)#fixed wing, APM, manual mode
        tLast = time.clock()
    print i
