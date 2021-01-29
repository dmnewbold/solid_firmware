#!/usr/bin/python

# General IPbus register getter / setter script
# each stdin line like 'reg_name' causes a read; each stdin line like 'reg_name:value' causes a write
#
# Dave Newbold, December 2020

import uhal
import time
import sys
import argparse

parser = argparse.ArgumentParser(description="IPbus general getter / setter script")
parser.add_argument('-c', "--connections-file", help = "specify connections file", default = "connections.xml")
parser.add_argument('device', help = "device name")
args = parser.parse_args()

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://" + args.connections_file)
hw = manager.getDevice(args.device)

while True:
    line = sys.stdin.readline().rstrip('\n')
    if not line:
        break
    if ':' in line:
        (r, v) = line.split(':')
        hw.getNode(r).write(int(v, 0))
        hw.dispatch()
        print r, "<-", v
    else:
        v = hw.getNode(line).read()
        hw.dispatch()
        print line, 'is', hex(v)
