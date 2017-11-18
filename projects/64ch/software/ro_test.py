#!/usr/bin/python

import uhal
from time import sleep
import sys
import collections

def zsdot(i):
	return ' ' if i == 0 else '*'

def zsfmt(i):
	return "%s%s%04x %s%s%04x" % (zsdot(i & 0x8000), zsdot(i & 0x4000), i & 0x3fff,
		zsdot(i & 0x80000000), zsdot(i & 0x40000000), (i & 0x3fff0000) >> 16)

def dump():
	b0 = board.getNode("daq.trig.csr.evt_ctr").read() # Event counter
	b1 = board.getNode("daq.trig.csr.stat").read() # Trigger block status
	b2 = board.getNode("daq.roc.csr.stat").read() # ROC status
	b3 = board.getNode("daq.roc.buf.count").read() # ROC buffer count
	b4 = board.getNode("daq.roc.csr.tot_data").read() # ROC total data issued
	b5 = board.getNode("daq.chan.csr.stat").read() # Channel status
	b6 = board.getNode("daq.roc.csr.wctr").read() # Debug - not important
	board.dispatch()
	
	print "Evt_ctr: %08x Trig_stat: %08x Roc_stat: %08x Buf_cnt: %08x Roc_tot: %08x Chan_stat: %08x Wctr: %08x" % (int(b0), int(b1), int(b2), int(b3), int(b4), int(b5), int(b6))

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
board = manager.getDevice(sys.argv[1])
board.getClient().setTimeoutPeriod(10000)

v = board.getNode("csr.id").read()
board.dispatch()
print "Board ID:", hex(v)

board.getNode("daq.timing.csr.ctrl.rst").write(1) # Hold clk40 domain in reset
board.dispatch()

board.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
board.dispatch()

sleep(1)

for i in range(1):
        board.getNode("csr.ctrl.chan").write(i) # Talk to channel 0
        board.getNode("daq.chan.csr.ctrl.mode").write(0x0) # Set to normal DAQ mode
        board.getNode("daq.chan.csr.ctrl.src").write(0x3) # Set source to fake data
        board.getNode("daq.chan.zs_thresh").writeBlock([0x0, 0x1]) # Set ZS thresholds #0 = 0, #1 =1
	board.getNode("daq.chan.trig_thresh.threshold.thresh").write(0x1000) # Set ctrig 0 threshold
        board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel

board.getNode("daq.fake.ctrl.mode").write(0x1) # Set fake data to pulse
board.getNode("daq.fake.ctrl.samp_lock").write(0x1) # Lock to sample
board.getNode("daq.fake.params.freq.freq_div").write(0x0) # Fake pulse once per 4096 samples
board.getNode("daq.fake.params.freq.samp").write(0xfd) # pulse on sample 0
board.getNode("daq.fake.params.freq.n").write(0x1) # One ping only
board.getNode("daq.fake.params.size.level").write(0x2000) # Pulse height
board.getNode("daq.fake.params.size.ped").write(0x0) # Pedestal
#board.getNode("daq.rtrig.ctrl.dist").write(0x1) # Set random trigger generator to interval mode
#board.getNode("daq.rtrig.ctrl.div").write(0x3) # Set random trigger rate to 40MHz / 2^11 = 20kHz
#board.getNode("daq.rtrig.ctrl.en").write(0x1) # Enable random trigger generator
#board.getNode("daq.trig.loc_mask").write(0x8) # Enable trigger type 3 (random trigger)
#board.getNode("daq.trig.seq.conf.addr").write(0x3) # Set sequencer table pointer to entry 3 (trigger type 3)
#board.getNode("daq.trig.seq.conf.data").write(0x00010000) # Set offset = 0, block count = 1
board.getNode("daq.trig.masks").write(0x1) # Enable ctrig bit 0 for channel 0
board.getNode("daq.trig.loc_mask").write(0x1) # Enable trigger type 0 (threshold trigger)
board.getNode("daq.trig.seq.conf.addr").write(0x0) # Set sequencer table pointer to entry 0
board.getNode("daq.trig.seq.conf.data").write(0x00040000) # Set offset = 0, block count = 4
board.getNode("daq.trig.zs_cfg").write(0x01) # Set zs thresh #1 for trigger 0
board.getNode("daq.roc.csr.ctrl.en").write(0x1) # Enable readout buffer
board.getNode("daq.timing.csr.ctrl.zs_blks").write(0x2) # Configure buffers for two ZS blocks
board.getNode("daq.timing.csr.ctrl.pipeline_en").write(1) # Enable front-end pipeline
board.getNode("daq.timing.csr.ctrl.force_sync").write(1) # And... go.
board.dispatch()

print "Started DAQ"

sleep(1)

r = list()
evts = 0
max_evts = 16
n_trig = 4

print "Firing triggers"

for i in range(1):
	board.getNode("daq.fake.ctrl.force").write(0x1)
	board.getNode("daq.fake.ctrl.force").write(0x0)
	board.dispatch()

while True:

	while True:
		v1 = board.getNode("daq.roc.buf.count").read() # Get the buffer data count
		board.dispatch()
		if v1 != 0:
			break

	b = board.getNode("daq.roc.buf.data").readBlock(int(v1)) # Read the buffer contents
	board.dispatch()

	r += b;
	
	while len(r) > 0:

                m = int(r[0])
		if (m >> 24) != 0xaa:
			print "Bad news: event header incorrect"
			dump()
			print "%08x" % m
			for i in range(len(r)):
				print "%08x" % int(r[i])
			sys.exit()
		l = m & 0xffff
		if len(r) >= l:
                        w0 = int(r.pop(0))
			w1 = int(r.pop(0))
			rtype = (w1 >> 28)
                        print "Shop! w0: %08x w1: %08x ro_type: %d len: %04x" % (w0, w1, rtype, l)
			if rtype == 0: # A data block
				bctr = w1 & 0xffffff
				tstamp = int(r.pop(0)) | (int(r.pop(0)) << 32)
				mask = int(r.pop(0)) | int(r.pop(0)) >> 32
				for _ in range(2):
					r.pop(0)
				c = bin(mask).count('1')
				print "\tctr: %08x time: %012x mask: %016x chans: %02x" % (bctr, tstamp, mask, c)
				tcnt = 0
				for i in range(c):
                                        print "\tchan %02x" % (i)
					print "\t\t%04x" % 0,
					cnt = 0
					zcnt = 0
					while True:
						cnt += 1;
						g = int(r.pop(0))
						if g & 0x4000 == 0:
							zcnt += 1
						else:
							zcnt += (g & 0x3fff)
						if g & 0x8000 == 0:
							if g & 0x40000000 == 0:
								zcnt += 1
							else:
								zcnt += ((g & 0x3fff0000) >> 16)						
						print zsfmt(g),
						if cnt % 8 == 0:
							print "\n\t\t%04x" % cnt,
						if g & 0x80008000 != 0:
							print
							break;
					print "\t\tlen: %04x" % cnt, "zlen: %04x" % zcnt
					if zcnt != 0x100:
						print "Bad news: chan %02x zcnt is %04x" % (i, zcnt)
						dump()
						sys.exit()
					tcnt += cnt
				if tcnt != l - 7:
					r.pop(0)
				evts += 1
				if evts >= max_evts:
					sys.exit()
			elif rtype == 1: # A trigger block
				ttype = w1 & 0x3ffff
				tstamp = int(r.pop(0)) | (int(r.pop(0)) << 32)
				for _ in range(2 * n_trig + 1):
#					print hex(r.pop(0))
					r.pop(0)
				print "\ttbits: %08x time: %012x" % (ttype, tstamp)
			else:
				print "Unknown readout type"
				sys.exit()
		else:
			break
