#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore
from si5344 import si5344
import time

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
hw = manager.getDevice(sys.argv[1])

while True:
    hw.getNode("daq.timing.csr.ctrl.cap_ctr").write(1)
    fw = hw.getNode("daq.timing.csr.stat.wait_sync").read();
    fl = hw.getNode("daq.timing.csr.sctr_l").read();
    fh = hw.getNode("daq.timing.csr.sctr_h").read();
    fs = hw.getNode("daq.timing.csr.sync_ctr").read();
    ft = hw.getNode("daq.timing.csr.trig_ctr").read();
    fe = hw.getNode("daq.timing.csr.stat.sync_err").read();
    hw.dispatch()
    print time.ctime(), "\twait_sync, sync_err, sctr_l, sctr_h, sync_ctr, trig_ctr:", hex(fw), hex(fe), hex(fl), hex(fh), hex(fs), hex(ft)
    time.sleep(1)
