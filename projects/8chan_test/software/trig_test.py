#!/usr/bin/python

import uhal
from time import sleep
import sys
import collections

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
board = uhal.getDevice("board", "ipbusudp-2.0://192.168.235.1:50001", "file://addrtab/top.xml")
#board.getClient().setTimeoutPeriod(10000)

v = board.getNode("csr.id").read()
board.dispatch()
print hex(v)

board.getNode("timing.csr.ctrl.rst").write(1) # Hold clk40 domain in reset
board.dispatch()

board.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
board.dispatch()

sleep(1)

#board.getNode("csr.ctrl.chan").write(0x0) # Talk to channel 0
#board.getNode("chan.csr.ctrl.mode").write(0x0) # Set to normal DAQ mode
#board.getNode("chan.csr.ctrl.src").write(0x3) # Set source to random number generator
#board.getNode("chan.csr.ctrl.zs_thresh").write(0x2fff) # Set ZS threshold
#board.getNode("chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
#board.getNode("csr.ctrl.chan").write(0x1) # Talk to channel 1
#board.getNode("chan.csr.ctrl.mode").write(0x0)
#board.getNode("chan.csr.ctrl.src").write(0x3)
#board.getNode("chan.csr.ctrl.zs_thresh").write(0x1fff)
#board.getNode("chan.csr.ctrl.en_buf").write(0x1)
board.getNode("trig.loc.rnd_mode").write(0x3) # Set random trigger generator to Poisson mode
board.getNode("trig.loc.rnd_div").write(0xa) # Set random trigger rate to 40MHz / 2^11 = 20kHz
board.getNode("trig.loc.trig_en").write(0x1) # Enable trigger type 0 (random trigger)
board.getNode("trig.seq.conf.addr").write(0x0) # Set sequencer table to entry 0 (trigger type 0) 
board.getNode("trig.seq.conf.data").write(0x00010000) # Set offet = 0, block count = 1 for trigger type 0
board.getNode("timing.csr.ctrl.force_sync").write(1) # And... go.
board.dispatch()

for j in range(100):

	sleep(1)
	
	board.getNode("trig.seq.ctrs.addr").write(0)
	tv = board.getNode("trig.seq.ctrs.data").readBlock(2)
	board.dispatch()
	
	for i in range(len(tv)):
		print hex(j), hex(i), hex(tv[i])
