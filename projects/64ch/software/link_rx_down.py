#!/usr/bin/python

import uhal
import time
import sys

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = []
for a in sys.argv[1:]:
    hw_list.append(manager.getDevice(a))

for hw in hw_list:
    print hw.id()

    v = hw.getNode("csr.id").read()
    vs = hw.getNode("csr.stat").read()
    hw.dispatch()
    print "csr.id", hex(v), "csr.stat", hex(vs)

    print "Disabling rx links"
    hw.getNode("daq.tlink.ctrl.en_us_rx").write(0)
    hw.getNode("daq.tlink.ctrl.en_ds_rx").write(0)
    hw.dispatch()

    hw.getNode("daq.tlink.ctrl.en_us_rx_phy").write(0)
    hw.getNode("daq.tlink.ctrl.en_ds_rx_phy").write(0)
    hw.dispatch()
