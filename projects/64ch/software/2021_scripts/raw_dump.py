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
    evts = 0
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

        if really_done: break

def zsdot(i, c):
    return ' ' if i == 0 else c

def zsfmt(i):
    return "%s%s%04x %s%s%04x" % (zsdot(i & 0x8000, 'E'), zsdot(i & 0x4000, 'Z'), i & 0x3fff,
                                  zsdot(i & 0x80000000, 'E'), zsdot(i & 0x40000000, 'Z'), (i & 0x3fff0000) >> 16)

r = array.array('L')
evts = 0
done = False

f = open(sys.argv[1], "rb")

start_time = time.time()
total_data = 0

while not done:

    try:
        r.fromfile(f, READ_SIZE)
    except EOFError:
        done = True

    while len(r) > 0:

        m = int(r[0])
        if (m >> 24) != 0xaa:
            print("Bad news: event header incorrect")
            dump()
            dumpstat()
            for i in range(len(r)):
                print("%08x" % int(r[i]))
            sys.exit()
        l = m & 0xffff
        if len(r) >= l:
            w0 = int(r.pop(0))
            w1 = int(r.pop(0))
            rtype = (w1 >> 28)
            print("Shop! w0: %08x w1: %08x ro_type: %d len: %04x" % (w0, w1, rtype, l))
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
                    print("\tchan %02x" % (i))
                    print("\t\t%04x" % 0, end = '')
                    cnt = 0
                    zcnt = 0
                    while True:
                        cnt += 1;
                        g = int(r.pop(0))
                        if g & 0x4000 == 0:
                            zcnt += 1
                        else:
                            zcnt += (g & 0x3fff) + 1
                        if g & 0x8000 == 0:
                            if g & 0x40000000 == 0:
                                zcnt += 1
                            else:
                                zcnt += ((g & 0x3fff0000) >> 16) + 1
                        print(zsfmt(g), end = '')
                        if cnt % 8 == 0:
                            print("\n\t\t%04x" % cnt, end = '')
                        if g & 0x80008000 != 0:
                            print()
                            break;
                    print("\t\tlen: %04x" % cnt, "zlen: %04x" % zcnt)
                    if zcnt != 0x100:
                        print("Bad news: chan %02x zcnt is %04x" % (i, zcnt))
                        dump()
                        sys.exit()
                    tcnt += cnt
                evts += 1
                if evts >= MAX_EVTS:
                    done = True
            elif rtype == 1: # A trigger block
                ttype = w1 & 0x3ffff
                tstamp = int(r.pop(0)) | (int(r.pop(0)) << 32)
                for _ in range(2 * N_TRIG + 1):
                    r.pop(0)
                print("\ttbits: %08x time: %012x" % (ttype, tstamp))
            else:
                print("Unknown readout type")
                sys.exit()
        else:
            break

f.close()
print("Elapsed time: %f" % (time.time() - start_time))
