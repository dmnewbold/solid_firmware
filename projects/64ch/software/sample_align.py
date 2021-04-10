#!/usr/bin/python
#
# This script configures the board for alignment testing, and fires a few triggers per slip / tap setting for analysis offline

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

CHANS = 64
TAPS = 32
BLOCKS_PER_TAP = 1
PAUSE = 1

INVERT = [0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25]

for i in range(CHANS):
    board.getNode("csr.ctrl.chan").write(i) # Talk to channel
    board.getNode("daq.chan.csr.ctrl.src").write(0) # Set source to real data
    board.getNode("daq.chan.zs_thresh").writeBlock(2 * [0x0]) # Set ZS thresholds #0 = 0x2000, #1 = 0x2000
    if i in INVERT:
        board.getNode("daq.chan.csr.ctrl.invert").write(0x1) # Invert the data
    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
    board.getNode("daq.chan.csr.ctrl.en_sync").write(0x1) # Enable sync commands

# Triggers

#board.getNode("daq.rtrig.ctrl.dist").write(0x1) # Set random trigger generator to interval mode
#board.getNode("daq.rtrig.ctrl.div").write(0x0a) # Set random trigger rate to 40MHz / 2^11 = 20kHz
#board.getNode("daq.rtrig.ctrl.en").write(0x1) # Enable random trigger generator
board.getNode("daq.trig.loc_mask").write(0x8) # Enable trigger type 3 (random trigger)

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

for i_tap in range(TAPS):
    print("Doing tap %d" % (i_tap))
    chstat = []
    for i in range(CHANS):
        board.getNode("csr.ctrl.chan").write(i) # Talk to channel
        chstat.append(board.getNode("daq.chan.csr.stat").read())
    board.dispatch()
    print("Stat:", [hex(int(x)) for x in chstat])
    for i_blk in range(BLOCKS_PER_TAP):
        board.getNode("daq.trig.csr.ctrl.force").write(0x1) # Fire a trigger
        board.dispatch()
        time.sleep(PAUSE)
    board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x1) # Increment tap
    board.dispatch()
