#!/usr/bin/python

import uhal
import time
import sys
import collections
import pickle

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

invert = [0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25]

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
#manager = uhal.ConnectionManager("file://connections.xml")
#board = manager.getDevice(sys.argv[1])
board = uhal.getDevice("board", "ipbusudp-2.0://192.168.235." + str(sys.argv[1]) + ":50001", "file://addrtab/top.xml")
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
patt = 0x1
cap_len = 0x10
taps_per_slip = 22

spi = board.getNode("io.spi")
spi_config(spi, 0xf, 0x2410, 0x1) # Divide 31.25MHz ipbus clock by 32; 16b transfer length, auto CSN; Enable SPI slave 0

for i in adcs:
    board.getNode("csr.ctrl.io_sel").write(i) # Select ADC bank to talk to
    board.dispatch()
    spi_write(spi, 0x0, 0x80) # Reset ADC
#    spi_write(spi, 0x1, 0x10) # Sleep
    spi_write(spi, 0x2, 0x05) # 14b 1 lane mode
    spi_write(spi, 0x3, 0x80 + (patt >> 8)) # Test pattern
    spi_write(spi, 0x4, patt & 0xff) # Test pattern

settings = []

for i_chan in chans:

    board.getNode("csr.ctrl.chan").write(i_chan) # Talk to correct channel
    board.getNode("daq.chan.csr.ctrl.mode").write(0x1) # Set to capture mode
    board.getNode("daq.chan.csr.ctrl.src").write(0x0) # Set source to ADC
    board.getNode("daq.chan.csr.ctrl.en_sync").write(0x1) # Enable sync commands
    if i_chan in invert:
        board.getNode("daq.chan.csr.ctrl.invert").write(0x1) # Invert the data
    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
    board.dispatch()

    res = [False] * (17 * taps_per_slip)
    tr = []
    swap = 0

    for i_slip in range(14):
        ok = False
        for i_tap in range(32):
#            atap = board.getNode("daq.chan.csr.stat.tap").read()
#            aslip = board.getNode("daq.chan.csr.stat.slip").read()
#            board.dispatch()
#            if i_slip != aslip or i_tap != atap:
#                print "Colossal bullshit has occured", hex(i_chan), hex(i_slip), hex(i_tap), hex(aslip), hex(atap)
#                sys.exit()
            board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x1) # Capture
            board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x0)
            board.dispatch()
            time.sleep(0.0001)
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
#               print hex(w),
#            print hex(i_chan), hex(i_slip), hex(i_tap), c
            res[i_slip * taps_per_slip - i_tap] = (c == cap_len)
            board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x1) # Increment tap
            board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x0)
            board.dispatch()
        if swap == 0:
            swap = 1
            board.getNode("daq.timing.csr.ctrl.chan_slip_h").write(0x1) # Increment slip
            board.getNode("daq.timing.csr.ctrl.chan_slip_h").write(0x0)
        else:
            swap = 0
            board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x1) # Increment slip
            board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x0)
        board.getNode("daq.chan.csr.ctrl.swap").write(swap)
        board.dispatch()

    trp = ""
    min = 0
    max = 0
    non_cont = False
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
    d_slip = 0
    d_tap = 0
    for i_slip in range(14):
        for i_tap in range(taps_per_slip):
            if a == i_slip * taps_per_slip - i_tap:
                d_slip = i_slip
                d_tap = i_tap
    print trp
    if not non_cont:
        print "Chan, rec_slip, rec_tap:", hex(i_chan), hex(d_slip), hex(d_tap)
        settings.append((i_chan, d_slip, d_tap))
    else:
        print "Chan, NON CONTINUOUS RANGE", hex(i_chan), trp

f = open(sys.argv[2], 'w')
pickle.dump(settings, f)
f.close()
