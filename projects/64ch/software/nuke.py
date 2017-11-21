#!/usr/bin/python

import uhal
import time
import sys

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
hw = manager.getDevice(sys.argv[1])

print "Boom"
hw.getNode("csr.ctrl.nuke").write(1) # Reset ipbus registers
hw.dispatch()
