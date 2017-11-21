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
#regCfgList=zeClock.parse_clk("Si5345-RevD-SOL64CZW-SOL64CHW-Registers.txt")
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

f = hw.getNode("csr.stat").read()
hw.dispatch()
print "csr.stat:", hex(f)

while int(f) & 0x1 == 0:
    print "Wait for MMCM lock"
    hw.getNode("csr.ctrl.rst_mmcm").write(1)
    hw.dispatch()
    hw.getNode("csr.ctrl.rst_mmcm").write(0)
    f = hw.getNode("csr.stat").read()
    hw.dispatch()

while int(f) & 0x2 == 0:
    print "Wait for IDELAYCTRL lock"
    hw.getNode("csr.ctrl.rst_idelayctrl").write(1)
    hw.dispatch()
    hw.getNode("csr.ctrl.rst_idelayctrl").write(0)
    hw.dispatch()
    f = hw.getNode("csr.stat").read()
    hw.dispatch()
    

f_ver = hw.getNode("csr.id").read()
hw.dispatch()
print "csr.id", hex(f_ver)

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
print "wait_sync, sync_err:", int(fw)
