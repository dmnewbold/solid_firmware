#!/usr/bin/python

import uhal
import time
import sys
import random
from I2CuHal import I2CCore
import dataset


# General settings

# DB
db_run = 'mysql://DAQGopher:gogogadgetdatabase@localhost/SoLid_Phase2_running'
# LogLevel
uhal.setLogLevelTo(uhal.LogLevel.ERROR)
# Board Connections
manager = uhal.ConnectionManager("file://solidfpga.xml")



# Setup connections with all planes

hw_list = []
result = run_db.query('SELECT ip FROM Configuration WHERE configID=(SELECT MAX(configID) from Configuration)')
for row in result:
    ip=row['ip']
    hw_list.append(manager.getDevice('SDB'+str(ip)))
run_db = None


for hw in hw_list:

'''
spi = hw.getNode("io.spi")
spi.getNode("divider").write(0xf) # Divide 31.25MHz ipbus clock by 32
spi.getNode("ctrl").write(0x2410) # 16b transfer length, auto CSN
spi.getNode("ss").write(0x1) # Enable SPI slave 0
hw.dispatch()

for i in range(0x10000):

    ci = random.randint(0x0, 0xf)
    di = random.randint(0x00,0xff)

    hw.getNode("csr.ctrl.io_sel").write(ci) # Select ADC bank to talk to
    spi.getNode("d0").write(0x0400 + di) # Write 0xa5 into register 0x4
    spi.getNode("ctrl").write(0x2510) # Do it
    hw.dispatch()

#       d = spi.getNode("d0").read()
#       c = spi.getNode("ctrl").read()
#       hw.dispatch()
#       print hex(d), hex(c)

    spi.getNode("d0").write(0x8400) # Read from register 0x4
    spi.getNode("ctrl").write(0x2510) # Do it
    hw.dispatch()

    d = spi.getNode("d0").read()
    c = spi.getNode("ctrl").read()
    hw.dispatch()

    if di != (d & 0xff) or (c & 0x100) != 0:
        print "Error:", hex(i), hex(ci), hex(di), hex(d), hex(c)
'''
