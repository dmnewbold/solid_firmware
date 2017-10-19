#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore
from si5344 import si5344

uhal.setLogLevelTo(uhal.LogLevel.INFO)
hw = uhal.getDevice("board", "ipbusudp-2.0://192.168.235.86:50001", "file://addrtab/top.xml")

hw.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
hw.dispatch()

hw.getNode("csr.ctrl.io_sel").write(9) # Talk via CPLD to Si5345
clock_I2C = I2CCore(hw, 10, 5, "io.i2c", None)
zeClock=si5344(clock_I2C)
res= zeClock.getDeviceVersion()
regCfgList=zeClock.parse_clk("Si5345-internal.txt")
zeClock.writeConfiguration(regCfgList)

hw.getNode("io.freq_ctr.ctrl.chan_sel").write(0);
hw.getNode("io.freq_ctr.ctrl.en_crap_mode").write(0);
hw.dispatch()
time.sleep(2)
fq = hw.getNode("io.freq_ctr.freq.count").read();
fv = hw.getNode("io.freq_ctr.freq.valid").read();
hw.dispatch()
print "Freq:", int(fv), int(fq) * 119.20928 / 1000000;

'''
f_stat = hw.getNode("csr.stat").read();
hw.dispatch()
print "csr.stat", hex(f_stat)

f_ctrl = hw.getNode("csr.ctrl").read();
hw.dispatch()
print "csr.ctrl:", hex(f_ctrl)

f_ctrl_2 = hw.getNode("daq.trig.csr.stat").read();
hw.dispatch()
print "daq.trig.csr.stat", hex(f_ctrl_2)

# Checks for sync
fw = hw.getNode("daq.timing.csr.stat.wait_sync").read();
hw.dispatch()
#print "wait_sync, sync_err:", int(fw), int(fs)
'''
