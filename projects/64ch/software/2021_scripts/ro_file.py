#!/usr/bin/python

# The script does the readout loop and writes the data to a file

from __future__ import print_function

import uhal
import time
import sys
import collections
import array

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
board = manager.getDevice(sys.argv[1])
board.getClient().setTimeoutPeriod(10000)

v = board.getNode("csr.id").read()
board.dispatch()
print("Board ID:", hex(v))

evts = 0
total_data = 0
max_data = 1024 * 1024 # 4kB
n_trig = 4
pval = 0.05 # Start at 50ms
pmax = 1 # No more than 1s per read check
ptarget = 1024

p = 8 * [0]

print("Waiting for running signal")
while True:
    b = board.getNode("daq.timing.csr.stat.running").read()
    board.dispatch()
    if b == 1:
        print("Running")
        break
    time.sleep(pval)

f = open(sys.argv[2], "wb")

start_time = time.time()

while total_data < max_data:
	
	while True:
		
		time.sleep(pval)
		v1 = board.getNode("daq.roc.buf.count").read() # Get the buffer data count
		board.dispatch()
		p.pop(0)
		p.append(v1)
		av_sz = sum(p) / len(p)
		pval = pval * av_sz / ptarget
		if pval > pmax: pval = pmax
		print("delay now %fs" % pval)
		if v1 != 0: break

        print("Reading out %dB" % (v1))
		total_data += v1
		b = board.getNode("daq.roc.buf.data").readBlock(int(v1)) # Read the buffer contents
		board.dispatch()
		array.array('L', b).tofile(f)
        f.flush()
    
f.close()
print("%d bytes at %fkB/s" % (total_data, float(total_data) / (time.time() - start_time)))
