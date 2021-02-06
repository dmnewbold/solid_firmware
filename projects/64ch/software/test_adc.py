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
manager = uhal.ConnectionManager("file://connections.xml")
board = manager.getDevice(sys.argv[1])
board.getClient().setTimeoutPeriod(10000)

v = board.getNode("csr.id").read()
board.dispatch()

board.getNode("daq.timing.csr.ctrl.rst").write(1) # Hold clk40 domain in reset
board.dispatch()

board.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
board.dispatch()

time.sleep(1)

adcs = range(0x10)
patt = 0x3830
cap_len = 0x400
reps = 0x100

spi = board.getNode("io.spi")
spi_config(spi, 0xf, 0x2410, 0x1) # Divide 31.25MHz ipbus clock by 32; 16b transfer length, auto CSN; Enable SPI slave 0

for i in adcs:
    board.getNode("csr.ctrl.io_sel").write(i) # Select ADC bank to talk to
    board.dispatch()
    spi_write(spi, 0x0, 0x80) # Reset ADC
    spi_write(spi, 0x2, 0x05) # 14b 1 lane mode
    spi_write(spi, 0x3, 0x80 + (patt >> 8)) # Test pattern
    spi_write(spi, 0x4, patt & 0xff) # Test pattern

f = open(sys.argv[2])
settings = pickle.load(f)
f.close()

for s_ch in settings:

    (i_chan, i_slip, i_tap) = s_ch

    board.getNode("csr.ctrl.chan").write(i_chan) # Talk to correct channel
    board.getNode("daq.chan.csr.ctrl.mode").write(0x1) # Set to capture mode
    board.getNode("daq.chan.csr.ctrl.src").write(0x0) # Set source to ADC
    board.getNode("daq.chan.csr.ctrl.en_sync").write(0x1) # Enable sync commands
    if i_chan in invert:
        board.getNode("daq.chan.csr.ctrl.invert").write(0x1) # Invert the data
    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
    board.dispatch()

    for _ in range(i_slip):
        board.getNode("daq.timing.csr.ctrl.chan_slip").write(0x1) # Increment slip
        board.getNode("daq.timing.csr.ctrl.chan_slip").write(0x0)
        board.dispatch()

    for _ in range(i_tap):
        board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x1) # Increment tap
        board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x0)
        board.dispatch()


    atap = board.getNode("daq.chan.csr.stat.tap").read()
    aslip = board.getNode("daq.chan.csr.stat.slip").read()
    board.dispatch()
    if i_slip != aslip or i_tap != atap:
        print "Colossal bullshit has occured"
        sys.exit()

    board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x1) # Capture
    board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x0)
    board.dispatch()

    c = 0
    for i in range(reps):
        while True:
            r = board.getNode("daq.chan.csr.stat").read()
            board.getNode("daq.chan.buf.addr").write(0x0)
            d = board.getNode("daq.chan.buf.data").readBlock(cap_len)
            board.dispatch()
            if r & 0x1 == 1:
                break
                print "Crap no capture", hex(i_chan), hex(i_slip), hex(i_tap), hex(r), time.clock()

        for w in d:
            if int(w) & 0x3fff == patt:
                c += 1

    print hex(i_chan), hex(i_slip), hex(i_tap), hex(c)
    if c != cap_len * reps:
        print "Failure"
        sys.exit()

    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x0) # Disable this channel
    board.getNode("daq.chan.csr.ctrl.en_sync").write(0x0) # Disable sync commands
    board.dispatch()
