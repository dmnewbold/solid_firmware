#!/usr/bin/python

import uhal
import time
#import sys
#from I2CuHal import I2CCore
import dataset


# General settings

# DB
db_run = 'mysql://DAQGopher:gogogadgetdatabase@localhost/SoLid_Phase2_running'
# LogLevel
uhal.setLogLevelTo(uhal.LogLevel.ERROR)
# Board Connections
manager = uhal.ConnectionManager("file://solidfpga.xml")



# Setup connections with all planes

board_list = []
result = run_db.query('SELECT ip FROM Configuration WHERE configID=(SELECT MAX(configID) from Configuration)')
for row in result:
    ip=row['ip']
    board_list.append(manager.getDevice('SDB'+str(ip)))
run_db = None


for board in board_list:

    # Check firmware version of the board
    fw = board.getNode("csr.id").read()
    hw.dispatch()
    print "Firmware version", fw&0xffff

    # Check the status of the clock and synchronisation
    se = board.getNode("daq.timing.csr.stat").read()
    board.dispatch()
    # The script check_sync.py does some more reading. Not sure if this is useful?


    # Check the status of the board to board links
    # Check status on up link, I think?
    vu = board.getNode("daq.tlink.us_stat").read()
    # Check status on down link, I think?
    vd = board.getNode("daq.tlink.ds_stat").read()
    hw.dispatch()
    # Copied from the script test_links.py, but do we need all this info?
    #print "us -- rdy_tx, buf_tx, stat_tx:", (vu & 0x1), hex((vu & 0xc) >> 2), hex((vu & 0x300) >> 8)
    #print "us -- rdy_rx, buf_rx, stat_rx:", (vu & 0x2) >> 1, hex((vu & 0x70) >> 4), hex((vu & 0x7c00) >> 10)
    #print "us -- remote_id", hex((vu & 0xff0000) >> 16)
    #print "ds -- rdy_tx, buf_tx, stat_tx:", (vd & 0x1), hex((vd & 0xc) >> 2), hex((vd & 0x300) >> 8)
    #print "ds -- rdy_rx, buf_rx, stat_rx:", (vd & 0x2) >> 1, hex((vd & 0x70) >> 4), hex((vd & 0x7c00) >> 10)
    #print "ds -- remote_id", hex((vd & 0xff0000) >> 16)


    # Control / status registers for the channels
    # Loop over the channels
    for chan in range(64):
        board.getNode("csr.ctrl.chan").write(i)
        bf = baord.getNode("daq.chan.csr.stat").read()
        board.dispatch()
        
