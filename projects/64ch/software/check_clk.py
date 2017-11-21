#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore
from si5344 import si5344

uhal.setLogLevelTo(uhal.LogLevel.INFO)
manager = uhal.ConnectionManager("file://connections.xml")
hw = manager.getDevice(sys.argv[1])

hw.getNode("io.freq_ctr.ctrl.chan_sel").write(0);
hw.getNode("io.freq_ctr.ctrl.en_crap_mode").write(0);
hw.dispatch()
time.sleep(2)
fq = hw.getNode("io.freq_ctr.freq.count").read();
fv = hw.getNode("io.freq_ctr.freq.valid").read();
hw.dispatch()
print "Freq:", int(fv), int(fq) * 119.20928 / 1000000;

hw.getNode("daq.timing.csr.ctrl.en_ext_sync").write(0)

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
