#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore

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

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
hw = uhal.getDevice("board", "ipbusudp-2.0://192.168.235.50:50001", "file://addrtab/top.xml")

spi = hw.getNode("io.spi")
spi_config(spi, 0xf, 0x2410, 0x1) # Divide 31.25MHz ipbus clock by 32; 16b transfer length, auto CSN; Enable SPI slave 0

for i in range(0xf):
    print "Set bank to:", hex(i)
    hw.getNode("csr.ctrl.io_sel").write(i) # Select ADC bank to talk to
    hw.dispatch()
    spi_write(spi, 0x0, 0x80) # Reset ADC
    spi_write(spi, 0x2, 0x05) # 14b 1 lane mode
    spi_write(spi, 0x3, 0xbf) # ALl zeroes test pattern
    spi_write(spi, 0x4, 0xff) # All zeroes test pattern
    print hex(spi_read(spi, 0x2)), hex(spi_read(spi, 0x3)), hex(spi_read(spi, 0x4))
