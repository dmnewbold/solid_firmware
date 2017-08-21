#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
hw = uhal.getDevice("board", "ipbusudp-2.0://192.168.235.50:50001", "file://addrtab/top.xml")

#hw.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
#hw.dispatch()

hw.getNode("csr.ctrl.io_sel").write(6) # Talk via CPLD to ADC #3 Bank A SPI
spi = hw.getNode("io.spi")
spi.getNode("divider").write(0xf) # Divide 31.25MHz ipbus clock by 32
spi.getNode("ctrl").write(0x2010) # 16b transfer length, auto CSN
hw.dispatch()

spi.getNode("d0").write(0x04a5) # Write 0xa5 into register 0x4
spi.getNode("ctrl").write(0x2110) # Do it
hw.dispatch()

d = spi.getNode("d0").read()
c = spi.getNode("ctrl").read()
hw.dispatch()
print hex(d), hex(c)

spi.getNode("d0").write(0x8400) # Read from register 0x4
spi.getNode("ctrl").write(0x2110) # Do it
hw.dispatch()

d = spi.getNode("d0").read()
c = spi.getNode("ctrl").read()
hw.dispatch()
print hex(d), hex(c)
