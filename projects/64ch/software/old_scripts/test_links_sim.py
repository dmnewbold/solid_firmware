#!/usr/bin/python

import uhal
import time
import sys

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
hw = manager.getDevice(sys.argv[1])

hw.getNode("daq.timing.csr.ctrl.rst").write(1) # Hold clk40 domain in reset
hw.dispatch()

hw.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
hw.dispatch()

v = hw.getNode("csr.id").read();
hw.dispatch()
print "csr.id", hex(v)

hw.getNode("daq.timing.csr.ctrl.cap_ctr").write(1)
hw.getNode("daq.timing.csr.ctrl.cap_ctr").write(0)
sl = hw.getNode("daq.timing.csr.sctr_l").read()
sh = hw.getNode("daq.timing.csr.sctr_h").read()
hw.dispatch()
print "Counter:", hex(int(sh) << 32 + int(sl))

vu = hw.getNode("daq.tlink.us_stat").read()
vd = hw.getNode("daq.tlink.ds_stat").read()
hw.dispatch()
print "us, ds:", hex(vu), hex(vd)

hw.getNode("daq.tlink.ctrl.rst_tx").write(1)
hw.getNode("daq.tlink.ctrl.rst_rx").write(1)
hw.getNode("daq.tlink.ctrl.en_us").write(1)
hw.getNode("daq.tlink.ctrl.en_ds").write(1)
hw.getNode("daq.tlink.ctrl.loop_us").write(0x2)
hw.getNode("daq.tlink.ctrl.loop_ds").write(0x2)
hw.dispatch()

hw.getNode("daq.tlink.ctrl.rst_tx").write(0)
hw.getNode("daq.tlink.ctrl.rst_rx").write(0)
hw.dispatch()

time.sleep(1)

vu = hw.getNode("daq.tlink.us_stat").read()
vd = hw.getNode("daq.tlink.ds_stat").read()
hw.dispatch()
print "us, ds:", hex(vu), hex(vd)
