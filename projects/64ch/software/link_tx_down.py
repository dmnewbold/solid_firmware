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

    print "Dropping tx links"
    hw.getNode("daq.tlink.ctrl.en_us_tx").write(0)
    hw.getNode("daq.tlink.ctrl.en_ds_tx").write(0)
    hw.getNode("daq.tlink.ctrl.en_us_tx_phy").write(0)
    hw.getNode("daq.tlink.ctrl.en_ds_tx_phy").write(0)
    hw.dispatch()

    vu = hw.getNode("daq.tlink.us_stat").read()
    vd = hw.getNode("daq.tlink.ds_stat").read()
    hw.dispatch()
    print "us -- rdy_tx, buf_tx, stat_tx:", (vu & 0x1), hex((vu & 0xc) >> 2), hex((vu & 0x300) >> 8)
    print "ds -- rdy_tx, buf_tx, stat_tx:", (vd & 0x1), hex((vd & 0xc) >> 2), hex((vd & 0x300) >> 8)
