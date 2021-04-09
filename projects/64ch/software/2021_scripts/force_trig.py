#!/usr/bin/python

# This script fires a few forced triggers of type 3

from __future__ import print_function

import uhal
import time
import sys
import collections

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
board = manager.getDevice(sys.argv[1])
board.getClient().setTimeoutPeriod(10000)

v = board.getNode("csr.id").read()
board.dispatch()
print("Board ID:", hex(v))

# Wait for startup

while True:
    b = board.getNode("daq.timing.csr.stat.running").read()
    board.dispatch()
    if b == 1:
        print("Running")
        break

# Send some triggers

print("Firing triggers")

for i in range(8):
    board.getNode("daq.trig.csr.ctrl.force").write(0x1)
    board.dispatch()
