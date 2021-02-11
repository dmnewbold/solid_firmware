#!/usr/bin/python

from __future__ import print_function

import sys
import collections
import array
import time

MAX_EVTS = 1000
N_TRIG = 4
READ_SIZE = 16 * 1024 # Read 64kB at a time

def get_evt(files):
	
	r = array.array('L')
	really_done = False
	
	for f in files:
		f = open(sys.argv[1], "rb")
		done = false

		while not done:
	
		try:
			r.fromfile(f, READ_SIZE)
		except EOFError:
			done = True
	
		while len(r) > 0:
	
			m = int(r[0])
			if (m >> 24) != 0xaa:
				print("Bad event header")
				really_done = True
				break
			l = m & 0xffff
			if len(r) >= l:
				w0 = r.pop(0)
				w1 = r.pop(0)
				rtype = (w1 >> 28)
				print("Shop! Type: %d w0: %08x w1: %08x  len: %04x" % (rtype, w0, w1, l))
				if rtype < 2:
					yield (rtype, l, r[:l])
				else:
					print("Bad readout type")
					really_done = True
					break
			else:
				break
		
		f.close()
		if really_done: break

def zsdot(i, c):
    return ' ' if i == 0 else c

def zsfmt(i):
    return "%s%s%04x %s%s%04x" % (zsdot(i & 0x8000, 'E'), zsdot(i & 0x4000, 'Z'), i & 0x3fff,
                                  zsdot(i & 0x80000000, 'E'), zsdot(i & 0x40000000, 'Z'), (i & 0x3fff0000) >> 16)

evts = 0
max_evts = 100
start_time = time.time()
total_data = 0

gen = get_evt([sys.argv[1]])

for (rtype, l, d) in gen:

	print("Got one")
	if rtype = 1: evts += 1
	if evts == max_evts: break

print("Elapsed time: %f" % (time.time() - start_time))
