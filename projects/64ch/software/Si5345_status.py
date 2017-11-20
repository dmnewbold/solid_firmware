#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore
from si5344 import si5344

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
hw = manager.getDevice(sys.argv[1])

hw.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
hw.dispatch()

hw.getNode("csr.ctrl.io_sel").write(9) # Talk via CPLD to Si5345
clock_I2C = I2CCore(hw, 10, 5, "io.i2c", None)
zeClock=si5344(clock_I2C)
res= zeClock.getDeviceVersion()
for ipage in range(10):
	for ireg in range(0x100):
		addr = (ipage << 8) + ireg
		print hex(addr), hex(zeClock.readRegister(addr, 1)[0])
