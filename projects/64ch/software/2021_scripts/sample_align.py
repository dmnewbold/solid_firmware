#!/usr/bin/python

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

board.getNode("daq.timing.csr.ctrl.rst").write(1) # Hold clk40 domain in reset
board.dispatch()

board.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
board.dispatch()

time.sleep(1)

chans = 64

for i in range(chans):
    board.getNode("csr.ctrl.chan").write(i) # Talk to channel
    board.getNode("daq.chan.csr.ctrl.src").write(0) # Set source to real data
    board.getNode("daq.chan.zs_thresh").writeBlock(2 * [0]) # Set ZS thresholds #0 = 0x2000, #1 = 0x2000
    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel

# Sequencer

board.getNode("daq.trig.seq.conf.addr").write(0x3) # Set sequencer table pointer to entry 3 (trigger type 3)
board.getNode("daq.trig.seq.conf.data").write(0x00010000) # Set offset = 0, block count = 1

# DAQ initialisation

print("Starting DAQ...")
board.getNode("daq.roc.csr.ctrl.en").write(0x1) # Enable readout buffer
board.getNode("daq.timing.csr.ctrl.zs_blks").write(0x2) # Configure buffers for two ZS blocks
board.getNode("daq.timing.csr.ctrl.nzs_blks").write(0x2) # Configure buffers for two NZS blocks
board.getNode("daq.timing.csr.ctrl.pipeline_en").write(1) # Enable front-end pipeline
board.getNode("daq.timing.csr.ctrl.force_sync").write(1) # And... go.
board.dispatch()
while True:
    b = board.getNode("daq.timing.csr.stat.running").read()
    board.dispatch()
    if b == 1:
        print("Running")
        break

