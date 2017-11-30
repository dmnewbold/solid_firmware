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

    v = hw.getNode("csr.id").read();
    vs = hw.getNode("csr.stat").read()
    vt = hw.getNode("daq.timing.csr.stat").read()
    hw.dispatch()
    print "csr.id", hex(v), "csr.stat", hex(vs), "timing.csr.stat", hex(vt)

    for i in ["us","ds"]:
        n = hw.getNode("daq.tlink."+i+"_stat")
        v_rdy_tx = n.getNode("phy_rdy_tx").read()
        v_rdy_rx = n.getNode("phy_rdy_rx").read()
        v_buf_tx = n.getNode("buf_tx").read()
        v_buf_rx = n.getNode("buf_tx").read()
        v_tx_empty = n.getNode("tx_empty").read()
        v_tx_full = n.getNode("tx_full").read()
        v_rx_empty = n.getNode("rx_empty").read()
        v_rx_full = n.getNode("rx_full").read()
        v_rx_up = n.getNode("rx_up").read()
        v_rx_fail = n.getNode("rx_fail").read()
        v_rx_cause = n.getNode("rx_cause").read()
        v_rem_id = n.getNode("remote_id").read()
        hw.dispatch()
        print i, "rdy_tx:", v_rdy_tx, "rdy_rx:", v_rdy_rx, "buf_tx:", v_buf_tx, "buf_rx", v_buf_rx, "tx_empty:", v_tx_empty, "tx_full:", v_tx_full, "rx_empty:", v_rx_empty, "rx_full:", v_rx_full, "rx_up:", v_rx_up, "rx_fail:", v_rx_fail, "rx_cause:", v_rx_cause, "remote_id:", v_rem_id
