#!/usr/bin/python
#
# This script is DEPRECATED - do not use

import uhal
from time import sleep
import sys
import collections

def zsdot(i, c):
    return ' ' if i == 0 else c

def zsfmt(i):
    return "%s%s%04x %s%s%04x" % (zsdot(i & 0x8000, 'E'), zsdot(i & 0x4000, 'Z'), i & 0x3fff,
                                  zsdot(i & 0x80000000, 'E'), zsdot(i & 0x40000000, 'Z'), (i & 0x3fff0000) >> 16)

def dump():
    b0 = board.getNode("daq.trig.csr.evt_ctr").read() # Event counter
    b1 = board.getNode("daq.trig.csr.stat").read() # Trigger block status
    b2 = board.getNode("daq.roc.csr.stat").read() # ROC status
    b3 = board.getNode("daq.roc.buf.count").read() # ROC buffer count
    b4 = board.getNode("daq.roc.csr.tot_data").read() # ROC total data issued
    b5 = board.getNode("daq.roc.csr.wctr").read() # Debug - not important
    board.dispatch()

    print "Evt_ctr: %08x Trig_stat: %08x Roc_stat: %08x Buf_cnt: %08x Roc_tot: %08x Wctr: %08x" % (int(b0), int(b1), int(b2), int(b3), int(b4), int(b5))

def dumpstat():

    cstat = []

    for i in range(chans):
        board.getNode("csr.ctrl.chan").write(i) # Talk to channel 0
        cstat.append(board.getNode("daq.chan.csr.stat").read())

    board.dispatch()
    print "Chan stat", [hex(int(x)) for x in cstat]

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

# Channel setup; need to read the constants from DB in real setup

chans = 64
srcs = chans * [0x3]
thresh = chans * [0x2000]
slip = chans * [0]
tap = chans * [0]

for i in range(chans):
    board.getNode("csr.ctrl.chan").write(i) # Talk to correct channel
    board.getNode("daq.chan.csr.ctrl.en_sync").write(1)
    board.getNode("daq.chan.csr.ctrl.src").write(srcs[i]) # Set source (real data, fkae data, etc)
    board.getNode("daq.chan.zs_thresh").writeBlock(2 * [thresh[i]]) # Set ZS thresholds
#    board.getNode("daq.chan.trig_thresh.threshold.thresh").write(0x1000) # Set ctrig 0 threshold
    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
    for j in range(slip[i]):
        board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x1)
    board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x0)
    for j in range(slip[i]):
        board.getNode("daq.timing.csr.ctrl.chan_slip_h").write(0x1)
    board.getNode("daq.timing.csr.ctrl.chan_slip_h").write(0x0)
    for j in range(tap[i]):
        board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x1)
    board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x0)
    board.dispatch()
    v_slip = board.getNode("daq.chan.csr.stat.slip").read()
    v_tap = board.getNode("daq.chan.csr.stat.tap").read()
    board.dispatch()
    if v_slip != slip[i] or v_tap != tap[i]:
        print "Bad delay values read back: set %d, %d read %d, %d" % (slip[i], tap[i], v_slip, v_tap)
        sys.exit()
    board.getNode("daq.chan.csr.ctrl.en_sync").write(0)

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
board.getNode("daq.rtrig.ctrl.div").write(0x09) # Set random trigger rate to 40MHz / 2^11 = 20kHz
board.getNode("daq.rtrig.ctrl.en").write(0x1) # Enable random trigger generator
#board.getNode("daq.rtrig.ctrl.en").write(0x0) # Enable random trigger generator
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
