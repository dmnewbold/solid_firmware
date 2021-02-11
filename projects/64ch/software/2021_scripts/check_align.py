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
		done = False

		while not done or really_done:

			try:
				r.fromfile(f, READ_SIZE)
			except EOFError:
				done = True
		
			while len(r) > 0:
		
				m = int(r[0])
				if (m >> 24) != 0xaa:
					print("Bad event header")
					print([hex(x) for x in r])
					really_done = True
					break
				l = m & 0xffff
				if len(r) >= l:
					w0 = r.pop(0)
					w1 = r[0]
					rtype = (w1 >> 28)
					print("Shop! Type: %d w0: %08x w1: %08x  len: %04x" % (rtype, w0, w1, l))
					if rtype < 2:
						yield (rtype, l, r[:l])
						del r[:l]
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

gen = get_evt(sys.argv[1:])

for (rtype, l, r) in gen:

	w1 = r.pop(0)
	
	if rtype == 0: # A data block
		bctr = w1 & 0xffffff
		tstamp = int(r.pop(0)) | (int(r.pop(0)) << 32)
		mask = int(r.pop(0)) | (int(r.pop(0)) << 32)
		c = bin(mask).count('1')
		print("\tctr: %08x time: %012x mask: %016x chans: %02x" % (bctr, tstamp, mask, c))
		tcnt = 0
		for i in range(64):
			if mask & (1 << i) == 0:
				continue
			print("Chan %02x present")


