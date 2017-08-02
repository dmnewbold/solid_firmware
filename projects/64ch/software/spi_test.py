#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
hw = uhal.getDevice("board", "ipbusudp-2.0://192.168.235.199:50001", "file://addrtab/top.xml")

hw.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
hw.dispatch()

spi = hw.getNode("io.spi")
spi.getNode("divider").write(0xf) # Divide 31.25MHz ipbus clock by 32
spi.getNode("ctrl").write(0x10) # 16b transfer length
hw.dispatch()

spi.getNode("d0").write(0x8000) # Write 0x00 into register 0x00
spi.getNode("ctrl").write(0x100) # Do it
hw.dispatch()

d = spi.getNode("d0").read()
c = spi.getNode("ctrl").read()
hw.dispatch()

print hex(d), hex(c)
