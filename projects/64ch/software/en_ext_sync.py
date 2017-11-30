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

    hw.getNode("daq.timing.csr.ctrl.en_ext_sync").write(1)
    hw.dispatch()

