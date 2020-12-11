#!/usr/bin/python

import uhal
import time
import sys
#from I2CuHal import I2CCore
import dataset
import pandas as pd # Very usefriendely, structured similarly as mysql and, according to the internet, it is the fastest way for reading/writing to files in python
import os
import datetime

# General settings

# DB
db_run = 'mysql://DAQGopher:gogogadgetdatabase@localhost/SoLid_Phase2_running'
# LogLevel
uhal.setLogLevelTo(uhal.LogLevel.ERROR)
# Board Connections
manager = uhal.ConnectionManager("file://DAQ_symlink/solidfpga.xml")
# id of this spi run
spi_id = 0 #TODO get the id from the argument or get last id from database if this script will contain the infinite loop


# Function to determine whethere the DAQ is taking data

def isTakingData():
    pids = [pid for pid in os.listdir('/proc') if pid.isdigit()]
    for pid in pids:
        try:
            proc_name = open(os.path.join('/proc', pid, 'cmdline'), 'rb').read()
            if 'DAQ_symlink/rundetector' in proc_name:
                return True

        except IOError: # proc has already terminated
            continue
    return False

if(not isTakingData()):
    print("DAQ is not taking data atm")
    sys.exit()


# Setup connections to all planes
board_list = []
run_db = dataset.connect(db_run)
result = run_db.query('SELECT ip FROM Configuration WHERE configID=(SELECT MAX(configID) from Configuration)')
for row in result:
    ip=row['ip']
    board_list.append(manager.getDevice('SDB'+str(ip)))
run_db = None


# Dictionaries to store all the information
infoGen = {'spi_id':[],'timestamp':[]} # If this script will contain the infinite loop, this can stay
infoPla = {'ip':[],'fw':[],'sync_stat':[],'us_stat':[],'ds_stat':[],'sctr_l':[],'sctr_h':[],'trig_stat':[],'evt_ctr':[],'spi_id':[]}
infoCha = {'channel':[],'chan_stat':[],'spi_id':[],'ip':[]}


infoGen['spi_id'].append(spi_id)
infoGen['timestamp'].append(datetime.datetime.utcnow().strftime("%Y_%m_%d"))

for board in board_list:

    # Check firmware version of the board
    fw = board.getNode("csr.id").read()
    board.dispatch()

    # TODO Check the voltages/currents on the fpga
    #clock_I2C = I2CCore(board, 10, 5, "i2c", None)

    # Check the status of the clock and synchronisation
    sync_stat = board.getNode("daq.timing.csr.stat").read()
    board.dispatch()
    # The script check_sync.py does some more reading. Not sure if this is useful?

    # Check the current timestamp
    board.getNode('daq.timing.csr.ctrl.cap_ctr').write(1)
    sctr_l = board.getNode('daq.timing.csr.sctr_l').read()
    sctr_h = board.getNode('daq.timing.csr.sctr_h').read()
    board.dispatch()

    # Check the status of the board to board links
    # Check status upstream
    us_stat = board.getNode("daq.tlink.us_stat").read()
    # Check status downstream
    ds_stat = board.getNode("daq.tlink.ds_stat").read()
    board.dispatch()

    # Check something of the trigger
    trig_stat = board.getNode('daq.trig.csr.stat').read()
    evt_ctr = board.getNode('daq.trig.csr.evt_ctr').read()
    board.dispatch()

    # Put the plane info in the dictionary
    infoPla['ip'].append(int(board.id()[3:]))
    infoPla['fw'].append(int(fw&0xffff)) # To be consistent, we should better not do the bitwise comparison here
    infoPla['sync_stat'].append(int(sync_stat))
    infoPla['us_stat'].append(int(us_stat))
    infoPla['ds_stat'].append(int(ds_stat))
    infoPla['sctr_l'].append(int(sctr_l))
    infoPla['sctr_h'].append(int(sctr_h))
    infoPla['trig_stat'].append(int(trig_stat))
    infoPla['evt_ctr'].append(int(evt_ctr))
    infoPla['spi_id'].append(int(spi_id))


    # Control / status registers for the channels
    # Loop over the channels
    for chan in range(64):
        board.getNode("csr.ctrl.chan").write(chan)
        chan_stat = board.getNode("daq.chan.csr.stat").read()
        board.dispatch()
        infoCha['channel'].append(chan)
        infoCha['chan_stat'].append(int(chan_stat))
        infoCha['spi_id'].append(int(spi_id))
        infoCha['ip'].append(int(board.id()[3:]))


# Convert dictionaries to pandas objects
dfGen = pd.DataFrame(data=infoGen)
dfPla = pd.DataFrame(data=infoPla)
dfCha = pd.DataFrame(data=infoCha)

dfGen.set_index('spi_id',inplace=True)

# Put all the info in the h5 file 
fOut = 'dfSpiResults_'+str(spi_id)+'.h5'
dfGen.to_hdf(fOut, key='GeneralTable', mode='w')
dfPla.to_hdf(fOut, key='PlaneTable')
dfCha.to_hdf(fOut, key='ChannelTable')
