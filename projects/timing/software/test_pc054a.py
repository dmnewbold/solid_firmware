# -*- coding: utf-8 -*-
import uhal
from I2CuHal import I2CCore
import time
from si5345 import si5345

import sys, getopt

try:
    opts,args = getopt.getopt(sys.argv[1:],"hl:o:i:",["layer=","output=","ip="])
except getopt.GetoptError:
    print "Bad arguments"
    sys.exit(2)

ipAddress = "192.168.235.199"
outputConnectorStr = 9
layerStr = "0"

for opt, arg in opts:
    if opt == '-h':
        print 'Some help'
        sys.exit()
    elif opt in ("-i", "--ip"):
        ipAddress = arg
    elif opt in ("-o", "--output"):
        outputConnectorStr = arg
    elif opt in ("-l","--layer"):
        layerStr = arg
        
outputConnector = int(outputConnectorStr)
layer = int(layerStr)

print 'Output connector is ', outputConnector
print 'IP address is ', ipAddress
print 'Layer is ',layer, " ( 0 = internal sync/trig )"

hw = uhal.getDevice("board", "ipbusudp-2.0://"+ ipAddress +":50001", "file://addrtab/top.xml")


reg = hw.getNode("csr.id").read()
hw.dispatch()
print "Firmware version = ", hex(reg)

# Configure to send Sync pulses...
hw.getNode("sync_ctrl.en_sync").write(0);
hw.dispatch()
print "Disabled sync pulses"

# reset counters etc.
#hw.getNode("csr.ctrl.soft_rst").write(1);
hw.getNode("sync_ctrl.rst_counters").write(1);
hw.dispatch()
print "Reset counters"

# Measure clock freq.
hw.getNode("freq_ctr.ctrl.chan_sel").write(0);
hw.getNode("freq_ctr.ctrl.en_crap_mode").write(0);
hw.dispatch()
time.sleep(1)
fq = hw.getNode("freq_ctr.freq.count").read();
fv = hw.getNode("freq_ctr.freq.valid").read();
hw.dispatch()
print "Freq:", int(fq) * 119.20928 / 1000000 , " MHz";
print "Freq status ( 1 = valid ) " , int(fv)

syncOutCtr = hw.getNode("csr.sync_out_ctr").read();
hw.dispatch()
print "sync out counter = ", syncOutCtr

trigOutCtr = hw.getNode("csr.trig_out_ctr").read();
hw.dispatch()
print "trig out counter = ", trigOutCtr

trigInCtr = hw.getNode("csr.trig_in_ctr").read();
hw.dispatch()
print "trig in counter = ", trigInCtr

# layer =0 --> generate local sync/trig pulses ( i.e. ignore  pulses on HDMI )
# layer =1 --> use trig/sync from HDMI ( i.e. ignore pulses from FPGA)
trigInCtr = hw.getNode("csr.ctrl.layer").write(layer);
hw.dispatch()

# Configure to send Sync pulses...
hw.getNode("sync_ctrl.en_sync").write(1);
hw.dispatch()
print "Enabled sync pulses"

time.sleep(2.0)

# Configure to stop Sync pulses...
hw.getNode("sync_ctrl.en_sync").write(0);
hw.dispatch()
print "Disabled sync pulses"


syncOutCtr = hw.getNode("csr.sync_out_ctr").read();
hw.dispatch()
print "sync out counter = ", syncOutCtr

trigInCtr = hw.getNode("csr.trig_in_ctr").read();
hw.dispatch()
print "trig in counter = ", trigInCtr

trigInMask = 1 << outputConnector
print "Setting trig in mask to " , hex(trigInMask)
#hw.getNode("csr.ctrl.trig_in_mask").write(0x3FF);
hw.getNode("csr.ctrl.trig_in_mask").write(trigInMask);
hw.dispatch()

hw.getNode("sync_ctrl.en_trig_out").write(1);
hw.dispatch()

# for i in range
#hw.getNode("sync_ctrl.force_trig_out").write(1);
#hw.dispatch()

trigOutCtr = hw.getNode("csr.trig_out_ctr").read();
hw.dispatch()
print "trig out counter = ", trigOutCtr

####
# Configure to send Sync pulses...
hw.getNode("sync_ctrl.en_sync").write(1);
hw.dispatch()
print "Enabled sync pulses"
