#!/usr/bin/python

# This script stops the readout pipeline - abruptly

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

board.getNode("daq.timing.csr.ctrl.pipeline_en").write(0) # Kill the pipeline
board.dispatch()
