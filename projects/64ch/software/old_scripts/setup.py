#!/usr/bin/python

import uhal
import time
import sys
from I2CuHal import I2CCore
from si5344 import si5344

sys.path.append('/home/dsaunder/workspace/go_projects/src/bitbucket.org/solidexperiment/readout-software/scripts')
import detector_config_tools
uhal.setLogLevelTo(uhal.LogLevel.ERROR)

ips = detector_config_tools.currentIPs(False)
slaveReadoutBoards = True
#ips = [92, 50, 88, 100, 86, 69, 53, 75, 60, 82] # Module Edgar.
ips = [92]

hw_list = []
for ip in ips:
    print 'Setting up readout board ip:', ip
    hw_list.append(uhal.getDevice("board", "ipbusudp-2.0://192.168.235." + str(ip) + ":50001", "file://addrtab/top.xml"))

ihw = -1
for hw in hw_list:
    ihw += 1
    print 'IP:', ips[ihw]
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

ihw = -1
for hw in hw_list:
    ihw += 1
    print 'IP:', ips[ihw]
    print hw.id()
    ver = hw.getNode("csr.id").read()
    hw.dispatch()
    print "Ver:", hex(ver)

    fq = hw.getNode("io.freq_ctr.freq.count").read();
    fv = hw.getNode("io.freq_ctr.freq.valid").read();
    hw.dispatch()
    print "Freq:", int(fv), int(fq) * 119.20928 / 1000000;
    if slaveReadoutBoards: hw.getNode("daq.timing.csr.ctrl.en_ext_sync").write(1)

    f = hw.getNode("csr.stat").read()
    hw.dispatch()
    print "csr.stat:", hex(f), int(f) & 0x1, int(f) & 0x2

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
