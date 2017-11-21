#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore
from si5344 import si5344

sys.path.append('/home/solid/workspace/go_projects/src/bitbucket.org/solidexperiment/readout-software/scripts')
import detector_config_tools
uhal.setLogLevelTo(uhal.LogLevel.ERROR)

#ips = detector_config_tools.currentIPs(False)
ips = [62, 72, 70, 71, 87, 94, 89, 85, 83, 68, 51, 61, 52, 63, 91, 81, 67, 73, 57, 102, 74, 59, 96, 90, 64, 98, 76, 104, 54, 58]
slaveReadoutBoards = True
>>>>>>> 770260c728da726f742260c3dfe27c8be7156add
for ip in ips:
    print 'Setting up readout board ip:', ip
    hw_list.append(uhal.getDevice("board", "ipbusudp-2.0://192.168.235." + str(ip) + ":50001", "file://addrtab/top.xml"))

for hw in hw_list:

    hw.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
    hw.dispatch()

    hw.getNode("csr.ctrl.io_sel").write(9) # Talk via CPLD to Si5345
    clock_I2C = I2CCore(hw, 10, 5, "io.i2c", None)
    zeClock=si5344(clock_I2C)
    res= zeClock.getDeviceVersion()
    if slaveReadoutBoards: regCfgList=zeClock.parse_clk("Si5345-RevD-SOL64CZW-SOL64CHW-Registers.txt")
    else: regCfgList=zeClock.parse_clk("Si5345-internal.txt")
    zeClock.writeConfiguration(regCfgList)

    hw.getNode("io.freq_ctr.ctrl.chan_sel").write(0);
    hw.getNode("io.freq_ctr.ctrl.en_crap_mode").write(0);
    hw.dispatch()

for hw in hw_list:

    print hw.id()
    ver = hw.getNode("csr.id").read()
    hw.dispatch()
    print "Ver:", hex(ver)

    fq = hw.getNode("io.freq_ctr.freq.count").read();
    fv = hw.getNode("io.freq_ctr.freq.valid").read();
    hw.dispatch()
    print "Freq:", int(fv), int(fq) * 119.20928 / 1000000;
#    if slaveReadoutBoards: hw.getNode("daq.timing.csr.ctrl.en_ext_sync").write(1)

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
    

