#!/usr/bin/python

import uhal
import time
import sys

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
hw = manager.getDevice(sys.argv[1])

v = hw.getNode("csr.id").read();
hw.dispatch()
print "csr.id", hex(v)

vu = hw.getNode("daq.tlink.us_stat").read()
vd = hw.getNode("daq.tlink.ds_stat").read()
hw.dispatch()
print "us -- rdy_tx, buf_tx, stat_tx:", (vu & 0x1), hex((vu & 0xc) >> 2), hex((vu & 0x300) >> 8)
print "us -- rdy_rx, buf_rx, stat_rx:", (vu & 0x2) >> 1, hex((vu & 0x70) >> 4), hex((vu & 0x7c00) >> 10)
print "us -- remote_id", hex((vu & 0xff0000) >> 16)
print "ds -- rdy_tx, buf_tx, stat_tx:", (vd & 0x1), hex((vd & 0xc) >> 2), hex((vd & 0x300) >> 8)
print "ds -- rdy_rx, buf_rx, stat_rx:", (vd & 0x2) >> 1, hex((vd & 0x70) >> 4), hex((vd & 0x7c00) >> 10)
print "ds -- remote_id", hex((vd & 0xff0000) >> 16)

hw.getNode("daq.tlink.ctrl.rst_tx").write(1)
hw.getNode("daq.tlink.ctrl.rst_rx").write(1)
hw.getNode("daq.tlink.ctrl.en_us").write(0)
hw.getNode("daq.tlink.ctrl.en_ds").write(0)
hw.getNode("daq.tlink.ctrl.loop_us").write(0x1)
hw.getNode("daq.tlink.ctrl.loop_ds").write(0x1)
hw.dispatch()

hw.getNode("daq.tlink.ctrl.en_us").write(1)
hw.getNode("daq.tlink.ctrl.en_ds").write(1)
hw.getNode("daq.tlink.ctrl.rst_tx").write(0)
hw.getNode("daq.tlink.ctrl.rst_rx").write(0)
hw.dispatch()

time.sleep(2)

vu = hw.getNode("daq.tlink.us_stat").read()
vd = hw.getNode("daq.tlink.ds_stat").read()
hw.dispatch()
print "us -- rdy_tx, buf_tx, stat_tx:", (vu & 0x1), hex((vu & 0xc) >> 2), hex((vu & 0x300) >> 8)
print "us -- rdy_rx, buf_rx, stat_rx:", (vu & 0x2) >> 1, hex((vu & 0x70) >> 4), hex((vu & 0x7c00) >> 10)
print "us -- remote_id", hex((vu & 0xff0000) >> 16)
print "ds -- rdy_tx, buf_tx, stat_tx:", (vd & 0x1), hex((vd & 0xc) >> 2), hex((vd & 0x300) >> 8)
print "ds -- rdy_rx, buf_rx, stat_rx:", (vd & 0x2) >> 1, hex((vd & 0x70) >> 4), hex((vd & 0x7c00) >> 10)
print "ds -- remote_id", hex((vd & 0xff0000) >> 16)
