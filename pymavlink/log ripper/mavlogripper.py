#!/usr/bin/env python

'''
example program that dumps a Mavlink log file. The log file is
assumed to be in the format that qgroundcontrol uses, which consists
of a series of MAVLink packets, each with a 64 bit timestamp
header. The timestamp is in microseconds since 1970 (unix epoch)
'''

import sys, time, os, struct

# allow import from the parent directory, where mavlink.py is
sys.path.insert(0, os.path.join(os.path.dirname(os.path.realpath(__file__)), '..'))

from optparse import OptionParser
parser = OptionParser("mavlogdump.py [options]")

parser.add_option("--no-timestamps",dest="notimestamps", action='store_true', help="Log doesn't have timestamps")
parser.add_option("--planner",dest="planner", action='store_true', help="use planner file format")
parser.add_option("--robust",dest="robust", action='store_true', help="Enable robust parsing (skip over bad data)")
parser.add_option("-f", "--follow",dest="follow", action='store_true', help="keep waiting for more data at end of file")
parser.add_option("--condition",dest="condition", default=None, help="select packets by condition")
parser.add_option("-q", "--quiet", dest="quiet", action='store_true', help="don't display packets")
parser.add_option("-o", "--output", default=None, help="output matching packets to give file")
parser.add_option("--types",  default=None, help="types of messages (comma separated)")
(opts, args) = parser.parse_args()

import mavutil

#filename = args[0]
filename = raw_input("Name of the .tlog file to be ripped:\n")
#remove the extension if present
if filename[-4:] == 'tlog':
    filename = filename[0:-5]

mlog = mavutil.mavlink_connection(filename+'.tlog', planner_format=opts.planner,
                                  notimestamps=opts.notimestamps,
                                  robust_parsing=opts.robust)

output = filename+'.txt'
outfile = open(filename+'.dat','w')

types = opts.types
if types is not None:
    types = types.split(',')
    
while True:
    m = mlog.recv_match(condition=opts.condition, blocking=opts.follow)
    if m is None:
        break
    
    if types is not None and m.get_type() not in types:
        continue
    last_timestamp = 0
    if m.get_type() != 'BAD_DATA':
        timestamp = getattr(m, '_timestamp', None)
        if not timestamp:
            timestamp = last_timestamp
        last_timestamp = timestamp
        outfile.write("%s.%02u: %s" % (
        time.strftime("%Y-%m-%d %H:%M:%S",
                      time.localtime(m._timestamp)),
        int(m._timestamp*100.0)%100, m))
        outfile.write("\n")
    if opts.quiet:
        continue
    print("%s.%02u: %s" % (
        time.strftime("%Y-%m-%d %H:%M:%S",
                      time.localtime(m._timestamp)),
        int(m._timestamp*100.0)%100, m))
    
        
