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

    print "Enabling rx links"
    hw.getNode("daq.tlink.ctrl.en_us_rx_phy").write(1)
    hw.getNode("daq.tlink.ctrl.en_ds_rx_phy").write(1)
    hw.dispatch()

    hw.getNode("daq.tlink.ctrl.en_us_rx").write(1)
    hw.getNode("daq.tlink.ctrl.en_ds_rx").write(1)
    hw.dispatch()
