#!/usr/bin/python
#
# This script reads the status of various functional blocks

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

if len(sys.argv) > 2:
    chans = int(sys.argv[2])
else:
    chans = 0

v = board.getNode("csr.stat").read()
board.dispatch()
print("csr.stat: %x" % (int(v)))

v = board.getNode("daq.timing.csr.stat").read()
board.dispatch()
print("daq.timing.csr.stat: %x" % (int(v)))

v = board.getNode("daq.tlink.us_stat").read()
v2 = board.getNode("daq.tlink.ds_stat").read()
board.dispatch()
print("daq.tlink.us_stat: %x" % (int(v)))
print("daq.tlink.ds_stat: %x" % (int(2)))

v = board.getNode("daq.trig.csr.stat").read()
v = board.getNode("daq.trig.csr.evt_ctr").read()
board.dispatch()
print("daq.trig.csr.stat: %x" % (int(v)))
print("daq.trig.csr.evt_ctr: %x" % (int(v2)))

v = board.getNode("daq.roc.csr.stat").read()
board.dispatch()
print("daq.roc.csr.stat: %x" % (int(v)))

for i in range(chans):
    board.getNode("csr.ctrl.chan").write(i)
    v = board.getNode("daq.chan.csr.stat").read()
    board.dispatch()
    print("chan %x stat: %x" % (i, int(v)))
