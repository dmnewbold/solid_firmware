#!/usr/bin/python

from __future__ import print_function

import uhal
import time
import sys
import collections

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

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
board = manager.getDevice(sys.argv[1])
board.getClient().setTimeoutPeriod(10000)

v = board.getNode("csr.id").read()
board.dispatch()
print("Board ID:", hex(v))

adcs = range(0x10)
patt = 0x2aa

spi = board.getNode("io.spi")
spi_config(spi, 0xf, 0x2410, 0x1) # Divide 31.25MHz ipbus clock by 32; 16b transfer length, auto CSN; Enable SPI slave 0

for i in adcs:
    board.getNode("csr.ctrl.io_sel").write(i) # Select ADC bank to talk to
    board.dispatch()
    spi_write(spi, 0x0, 0x80) # Reset ADC
    spi_write(spi, 0x2, 0x05) # 14b 1 lane mode
    spi_write(spi, 0x3, 0x80 + (patt >> 8)) # Test pattern
    spi_write(spi, 0x4, patt & 0xff) # Test pattern
