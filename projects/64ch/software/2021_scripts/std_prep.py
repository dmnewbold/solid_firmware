#!/usr/bin/python

# This script resets and sets up the board

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

srcs = 64 * [0x3]
thresh = 64 * [0x2000]

tap = 0
slip = 0
chans = 4
for i in range(chans):
    board.getNode("csr.ctrl.chan").write(i) # Talk to channel 0
    board.getNode("daq.chan.csr.ctrl.src").write(srcs[i]) # Set source to fake data
    board.getNode("daq.chan.zs_thresh").writeBlock(2 * [thresh[i]]) # Set ZS thresholds #0 = 0x2000, #1 = 0x2000
#    board.getNode("daq.chan.trig_thresh.threshold.thresh").write(0x1000) # Set ctrig 0 threshold
    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
#    for islip in range(slip):
#        board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x1)
#        board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x0)

#    for itap in range(tap):
#        board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x1)
#        board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x0)

# Fake data

#board.getNode("daq.fake.ctrl.mode").write(0x1) # Set fake data to pulse
#board.getNode("daq.fake.ctrl.samp_lock").write(0x1) # Lock to sample
#board.getNode("daq.fake.params.freq.freq_div").write(0x0) # Fake pulse once per 4096 samples
#board.getNode("daq.fake.params.freq.samp").write(0xfd) # pulse on sample 0
#board.getNode("daq.fake.params.freq.n").write(0x1) # One ping only
#board.getNode("daq.fake.params.size.level").write(0x2000) # Pulse height
#board.getNode("daq.fake.params.size.ped").write(0x0) # Pedestal

# Trigger generators

board.getNode("daq.rtrig.ctrl.dist").write(0x1) # Set random trigger generator to interval mode
board.getNode("daq.rtrig.ctrl.div").write(0x04) # Set random trigger rate to 40MHz / 2^11 = 20kHz
#board.getNode("daq.rtrig.ctrl.en").write(0x1) # Enable random trigger generator
board.getNode("daq.trig.loc_mask").write(0x8) # Enable trigger type 3 (random trigger)

# Sequencer

board.getNode("daq.trig.seq.conf.addr").write(0x3) # Set sequencer table pointer to entry 3 (trigger type 3)
board.getNode("daq.trig.seq.conf.data").write(0x00010000) # Set offset = 0, block count = 1

# Trigger setup

#board.getNode("daq.trig.masks").write(0x1) # Enable ctrig bit 0 for channel 0
#board.getNode("daq.trig.loc_mask").write(0x1) # Enable trigger type 0 (threshold trigger)
#board.getNode("daq.trig.seq.conf.addr").write(0x0) # Set sequencer table pointer to entry 0
#board.getNode("daq.trig.seq.conf.data").write(0x00040000) # Set offset = 0, block count = 4
#board.getNode("daq.trig.zs_cfg").write(0x01) # Set zs thresh #1 for trigger 0

# DAQ initialisation

print("Starting DAQ...")
board.getNode("daq.roc.csr.ctrl.en").write(0x1) # Enable readout buffer
board.getNode("daq.timing.csr.ctrl.zs_blks").write(0x2) # Configure buffers for two ZS blocks
board.getNode("daq.timing.csr.ctrl.nzs_blks").write(0x2) # Configure buffers for two NZS blocks
board.getNode("daq.timing.csr.ctrl.pipeline_en").write(1) # Enable front-end pipeline
board.getNode("daq.timing.csr.ctrl.force_sync").write(1) # And... go.
board.dispatch()

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