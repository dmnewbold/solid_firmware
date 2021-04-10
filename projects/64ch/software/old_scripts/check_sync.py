#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore
from si5344 import si5344
import time
sys.path.append('/home/dsaunder/workspace/go_projects/src/bitbucket.org/solidexperiment/readout-software/scripts/')
import detector_config_tools

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
ips = detector_config_tools.currentIPs(False)
#ips = [92, 50, 88, 100, 86, 69, 53, 75, 60, 82]
#manager = uhal.ConnectionManager("file://connections.xml")
#hw = manager.getDevice(sys.argv[1])

while True:
    print '\n', time.ctime(),
    sumSynced = 0
    sumErrs = 0
    for ip in ips:
        hw = uhal.getDevice("board", "ipbusudp-2.0://192.168.235." + str(ip) + ":50001", "file://addrtab/top.xml")
        hw.getNode("daq.timing.csr.ctrl.cap_ctr").write(1)
        #fw = hw.getNode("daq.timing.csr.stat.wait_sync").read();
        fl = hw.getNode("daq.timing.csr.sctr_l").read();
        fh = hw.getNode("daq.timing.csr.sctr_h").read();
        fs = hw.getNode("daq.timing.csr.sync_ctr").read();
        #ft = hw.getNode("daq.timing.csr.trig_ctr").read();
        fe = hw.getNode("daq.timing.csr.stat.sync_err").read();
        stat = hw.getNode("csr.stat").read()
        froc = hw.getNode("daq.roc.csr.stat").read()
        f_nhop = hw.getNode("daq.trig.hop_cfg").read()
        hw.dispatch()
        synced = int(fs) > 0
        #print int(synced), hex(froc), hex(stat),'  ',
        print int(synced), int(f_nhop),' ',
        sumSynced += int(synced)
        sumErrs += int(fe)

    print '\t', sumSynced, sumErrs,

    time.sleep(2)
