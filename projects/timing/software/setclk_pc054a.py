# -*- coding: utf-8 -*-
import uhal
from I2CuHal import I2CCore
import time
from si5345 import si5345

import sys, getopt

try:
    opts,args = getopt.getopt(sys.argv[1:],"hc:i:",["config=","ip="])
except getopt.GetoptError:
    print "Bad arguments"
    sys.exit(2)

#print "sys.argv = " , sys.argv 
#print "opts = " , opts

ipAddress = "192.168.235.199"
configFile = "./Si5344-RevD-SCLKSL03-Registers.txt"

for opt, arg in opts:
    if opt == '-h':
        print 'Some help'
        sys.exit()
    elif opt in ("-i", "--ip"):
        ipAddress = arg
    elif opt in ("-c", "--config"):
        configFile = arg
print 'Config file is ', configFile
print 'IP address is ', ipAddress

hw = uhal.getDevice("board", "ipbusudp-2.0://"+ ipAddress +":50001", "file://addrtab/top.xml")


reg = hw.getNode("csr.id").read()
hw.dispatch()
print "Firmware version = ", hex(reg)


# #First I2C core
print ("Instantiating master I2C core:")
master_I2C= I2CCore(hw, 10, 5, "i2c", None)
master_I2C.state()

#CLOCK CONFIGURATION BEGIN
zeClock=si5345(master_I2C, 0x68)
res= zeClock.getDeviceVersion()
zeClock.checkDesignID()
#zeClock.setPage(0, True)
#zeClock.getPage(True)
clkRegList= zeClock.parse_clk(configFile)

zeClock.writeConfiguration(clkRegList)######

zeClock.checkDesignID()


iopower= zeClock.readRegister(0x0949, 1)
print "  Clock IO power: 0x%X" % iopower[0]
lol= zeClock.readRegister(0x000E, 1)
print "  Clock LOL (0x000E): 0x%X" % lol[0]
los= zeClock.readRegister(0x000D, 1)
print "  Clock LOS (0x000D): 0x%X" % los[0]
#CLOCK CONFIGURATION END

hw.getNode("freq_ctr.ctrl.chan_sel").write(0);
hw.getNode("freq_ctr.ctrl.en_crap_mode").write(0);
hw.dispatch()
time.sleep(1)
fq = hw.getNode("freq_ctr.freq.count").read();
fv = hw.getNode("freq_ctr.freq.valid").read();
hw.dispatch()
print "Freq:", int(fq) * 119.20928 / 1000000 , " MHz";
print "Freq status ( 1 = valid ) " , int(fv)

