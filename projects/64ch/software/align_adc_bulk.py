#!/usr/bin/python

import dataset
import uhal
import time
import sys
import collections
sys.path.append('/home/dsaunder/workspace/go_projects/src/bitbucket.org/solidexperiment/readout-software/scripts/')
import detector_config_tools

def spi_config(spi, div, ctrl, ss):
    spi.getNode("divider").write(0xf) # Divide 31.25MHz ipbus clock by 32
    spi.getNode("ctrl").write(0x2410) # 16b transfer length, auto CSN
    spi.getNode("ss").write(0x1) # Enable SPI slave 0
    spi.getClient().dispatch()  

def spi_write(spi, addr, data):
    spi.getNode("d0").write((addr << 8) + data) # Write data into addr
    spi.getNode("ctrl").write(0x2510) # Do it
    spi.getClient().dispatch()
    r = spi.getNode("ctrl").read()
    spi.getClient().dispatch()
    if r & 0x100 != 0:
        print "SPI write error", hex(addr), hex(data)

def spi_read(spi, addr):
    spi.getNode("d0").write(0x8000 + (addr << 8)) # Read from addr
    spi.getNode("ctrl").write(0x2510) # Do it
    spi.getClient().dispatch()
    d = spi.getNode("d0").read()
    r = spi.getNode("ctrl").read()
    spi.getClient().dispatch()
    if r & 0x100 != 0:
        print "SPI read error", hex(addr)
    return d & 0xffff

offsets = [0, 13, 2, 1, 4, 3, 6, 5, 8, 7, 10, 9, 12, 11]
invert = [0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25]
# Db stuff. 
ips = detector_config_tools.currentIPs(False)
ips = [50]
db = dataset.connect('mysql://DAQGopher:gogogadgetdatabase@localhost/solid_phase1_running')
configID = 0 #first time case
if len(db['TapSlips']) != 0: configID = max(db['TapSlips']['configID'])['configID'] + 1
print 'Bulk scanning ips:', ips
print 'New TapSlips configID', configID
uhal.setLogLevelTo(uhal.LogLevel.ERROR)
iBoard = -1

for ith_ip in ips:
    iBoard += 1
    ith_slips, ith_taps = [], []
    print '\n\n*********** About to align ip:', ith_ip
    board = uhal.getDevice("board", "ipbusudp-2.0://192.168.235." + str(ith_ip) + ":50001", "file://addrtab/top.xml")
    board.getClient().setTimeoutPeriod(10000)
    v = board.getNode("csr.id").read()
    board.dispatch()

    board.getNode("daq.timing.csr.ctrl.rst").write(1) # Hold clk40 domain in reset
    board.dispatch()

    board.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
    board.dispatch()

    time.sleep(1)

    chans = range(0x40)
    adcs = range(0x10)
    patt = 0x0ff
    cap_len = 0x80
    taps_per_slip = 22

    spi = board.getNode("io.spi")
    spi_config(spi, 0xf, 0x2410, 0x1) # Divide 31.25MHz ipbus clock by 32; 16b transfer length, auto CSN; Enable SPI slave 0

    for i in adcs:
        board.getNode("csr.ctrl.io_sel").write(i) # Select ADC bank to talk to
        board.dispatch()
        spi_write(spi, 0x0, 0x80) # Reset ADC
        spi_write(spi, 0x2, 0x05) # 14b 1 lane mode
        spi_write(spi, 0x3, 0x80 + (patt >> 8)) # Test pattern
        spi_write(spi, 0x4, patt & 0xff) # Test pattern

    for i_chan in chans:
        workers = []
        board.getNode("csr.ctrl.chan").write(i_chan) # Talk to channel 0
        board.getNode("daq.chan.csr.ctrl.mode").write(0x1) # Set to capture mode
        board.getNode("daq.chan.csr.ctrl.src").write(0x0) # Set source to ADC
        board.getNode("daq.chan.csr.ctrl.en_sync").write(0x1) # Enable sync commands
        if i_chan in invert:
            board.getNode("daq.chan.csr.ctrl.invert").write(0x1) # Invert the data
        board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
        board.dispatch()
        
        res = [False] * (15 * taps_per_slip)
        tr = []
        for i_slip in range(14):
            ok = False
            for i_tap in range(32):
                board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x1) # Capture
                board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x0)
                board.dispatch()
                time.sleep(0.01)
                while True:
                    r = board.getNode("daq.chan.csr.stat").read()
                    board.getNode("daq.chan.buf.addr").write(0x0)
                    d = board.getNode("daq.chan.buf.data").readBlock(cap_len)
                    board.dispatch()
                    if r & 0x1 == 1:
                        break
                    print "Crap no capture", hex(i_chan), hex(i_slip), hex(i_tap), hex(r), time.clock()
                c = 0
                for w in d:
                    if int(w) & 0x3ff == patt:
                        c += 1
                        #print hex(w),
                        #print i_chan, i_slip, i_tap, c, '\t-\t', iBoard
                res[offsets[i_slip] * taps_per_slip - i_tap] = (c == cap_len)
                #res[i_slip * taps_per_slip + i_tap] = (c == cap_len)
                if c==cap_len: workers.append([i_slip, i_tap])
                ok = (c == cap_len) or ok
                board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x1) # Increment tap
                board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x0)
                board.dispatch()
            if ok:
                tr.append(i_slip)
            board.getNode("daq.timing.csr.ctrl.chan_slip").write(0x1) # Increment slip
            board.getNode("daq.timing.csr.ctrl.chan_slip").write(0x0)
            board.dispatch()
            
        trp = ""
        min = 0
        max = 0
        non_cont = False
        print workers, len(workers), workers[len(workers)/2]
        for i in range(len(res) - 1):
            if res[i + 1] and not res[i]:
                if min == 0:
                    min = i + 1
                else:
                    non_cont = True
            elif res[i] and not res[i + 1]:
                if max == 0:
                    max = i
                else:
                    non_cont = True
            if res[i] == None:
                trp += "_"
            elif res[i]:
                trp += "+"
            else:
                trp += "."
        a = int((min + max) / 2)    
        d_slip = offsets.index(a // taps_per_slip)
        d_tap = a % taps_per_slip
        db['TapSlips'].insert({'configID': int(configID), 'ip': ith_ip, 'tap': d_tap, 'slip': d_slip, 'channel': i_chan})
        ith_slips.append(d_slip)
        ith_taps.append(d_tap)
        #ith_slips.append(workers[len(workers)/2][0])
        #ith_taps.append(workers[len(workers)/2][1])
        print trp
        if not non_cont:
            print "Chan, rec_slip, rec_tap:", i_chan, d_slip, d_tap, '\t', iBoard
        else:
            print "Chan, NON CONTINUOUS RANGE", hex(i_chan), trp
    
    print 'ith_slips', ith_slips
    print 'ith_taps', ith_taps
