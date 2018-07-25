#!/usr/bin/python

import uhal
import time
import sys

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
hw_list = []
#manager = uhal.ConnectionManager("file://connections.xml")
#for a in sys.argv[1:]:
#    hw_list.append(manager.getDevice(a))

sys.path.append('/home/dsaunder/workspace/go_projects/src/bitbucket.org/solidexperiment/readout-software/scripts')
import detector_config_tools
ips = detector_config_tools.currentIPs(False)
for ip in ips:
    hw_list.append(uhal.getDevice("board", "ipbusudp-2.0://192.168.235." + str(ip) + ":50001", "file://addrtab/top.xml"))

for hw in hw_list:
    print hw.id()

    v = hw.getNode("csr.id").read()
    vs = hw.getNode("csr.stat").read()
    hw.dispatch()
    print "csr.id", hex(v), "csr.stat", hex(vs)

    print "Enabling tx links"
    hw.getNode("daq.tlink.ctrl.en_us_tx").write(1)
    hw.getNode("daq.tlink.ctrl.en_ds_tx").write(1)
    hw.getNode("daq.tlink.ctrl.en_us_tx_phy").write(1)
    hw.getNode("daq.tlink.ctrl.en_ds_tx_phy").write(1)
    hw.dispatch()

    vu = hw.getNode("daq.tlink.us_stat").read()
    vd = hw.getNode("daq.tlink.ds_stat").read()
    hw.dispatch()
    print "us -- rdy_tx, buf_tx, stat_tx:", (vu & 0x1), hex((vu & 0xc) >> 2), hex((vu & 0x300) >> 8)
    print "ds -- rdy_tx, buf_tx, stat_tx:", (vd & 0x1), hex((vd & 0xc) >> 2), hex((vd & 0x300) >> 8)
