#!/usr/bin/python

import uhal
from time import sleep
import sys
import collections

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

# Trigger generators

board.getNode("daq.trig.loc_mask").write(0x8) # Enable trigger type 3 (random trigger)

# Sequencer

board.getNode("daq.trig.seq.conf.addr").write(0x3) # Set sequencer table pointer to entry 3 (trigger type 3)
board.getNode("daq.trig.seq.conf.data").write(0x00010000) # Set offset = 0, block count = 1

# DAQ initialisation

print "Starting DAQ..."
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
        print "Running"
        break

r = list()
evts = 0
max_evts = 100000
n_trig = 4

chans = 64
for i in range(chans):
    board.getNode("csr.ctrl.chan").write(i) # Talk to channel 0
    board.getNode("daq.chan.csr.ctrl.src").write(0) # Set source to ADC data
    board.getNode("daq.chan.zs_thresh").writeBlock(4 * [0]) # Set ZS thresholds #0 = 0x2000, #1 = 0x2000
    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
#    for islip in range(slip):
#        board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x1)
#        board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x0)

#    for itap in range(tap): 
#        board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x1)
#        board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x0)


#print "Firing triggers"

#for i in range(8):
#    board.getNode("daq.trig.csr.ctrl.force").write(0x1)
#    board.dispatch()

while True:

    while True:
#        sleep(10)
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
            dumpstat()
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
                mask = int(r.pop(0)) | (int(r.pop(0)) << 32)
#                for _ in range(2):
#                    r.pop(0)
                c = bin(mask).count('1')
                print "\tctr: %08x time: %012x mask: %016x chans: %02x" % (bctr, tstamp, mask, c)
                tcnt = 0
                for i in range(chans):
                    if mask & (1 << i) == 0:
                        continue
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
                            zcnt += (g & 0x3fff) + 1
                        if g & 0x8000 == 0:
                            if g & 0x40000000 == 0:
                                zcnt += 1
                            else:
                                zcnt += ((g & 0x3fff0000) >> 16) + 1
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
#                if tcnt != l - 7:
#                    r.pop(0)
                evts += 1
                dumpstat()
                if evts >= max_evts:
                    sys.exit()
            elif rtype == 1: # A trigger block
                ttype = w1 & 0x3ffff
                tstamp = int(r.pop(0)) | (int(r.pop(0)) << 32)
                for _ in range(2 * n_trig + 1):
#                                       print hex(r.pop(0))
                    r.pop(0)
                print "\ttbits: %08x time: %012x" % (ttype, tstamp)
            else:
                print "Unknown readout type"
                sys.exit()
        else:
            break
