#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore
from si5344 import si5344

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
hw = uhal.getDevice("board", "ipbusudp-2.0://192.168.235.199:50001", "file://addrtab/top.xml")

hw.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
hw.dispatch()

clock_I2C = I2CCore(hw, 10, 5, "i2c", None)
zeClock=si5344(clock_I2C)
res= zeClock.getDeviceVersion()
regCfgList=zeClock.parse_clk("Si5344-RevD-SCLKMA02-Registers.txt") # CHANGE THE NAME OF THIS FILE
zeClock.writeConfiguration(regCfgList)

hw.getNode("freq_ctr.ctrl.chan_sel").write(0);
hw.getNode("freq_ctr.ctrl.en_crap_mode").write(0);
hw.dispatch()
time.sleep(2)
fq = hw.getNode("freq_ctr.freq.count").read();
fv = hw.getNode("freq_ctr.freq.valid").read();
hw.dispatch()
print "Freq:", int(fv), int(fq) * 119.20928 / 1000000;
