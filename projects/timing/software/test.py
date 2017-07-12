#!/usr/bin/python

import uhal
from time import sleep
import sys
import collections

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
board = uhal.getDevice("board", "ipbusudp-2.0://192.168.235.199:50001", "file://addrtab/top.xml")

board.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
board.dispatch()
