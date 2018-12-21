#!/usr/bin/python
#
# Take data from ADC
#
# Aligns slip and tap values for LTM9007 deserializer in SoLiD 8 channel firmware using slip_h and slip_l ( v19 firmware?)
#
# Based on code by Dave Newbold
#
# David Cussans, December 2018

import uhal
import time
import sys
import collections
import pickle

def spi_config(spi, div, ctrl, ss):
    spi.getNode("divider").write(div) # Divide 31.25MHz ipbus clock by 32
    spi.getNode("ctrl").write(ctrl) # 0x2410 = 16b transfer length, auto CSN
    spi.getNode("ss").write(ss) # Enable SPI slaves with bitmask SS
    spi.getClient().dispatch()

def spi_write(spi, addr, data):
    spi.getNode("d0").write((addr << 8) + data) # Write data into addr
    spi.getNode("ctrl").write(0x2510) # Do it
    spi.getClient().dispatch()
    r = spi.getNode("ctrl").read()
    spi.getClient().dispatch()
    if r & 0x100 != 0:
        print "SPI write error", hex(addr), hex(data)

def spi_read(spi, addr):
    spi.getNode("d0").write(0x8000 + (addr << 8)) # Read from addr
    spi.getNode("ctrl").write(0x2510) # Do it
    spi.getClient().dispatch()
    d = spi.getNode("d0").read()
    r = spi.getNode("ctrl").read()
    spi.getClient().dispatch()
    if r & 0x100 != 0:
        print "SPI read error", hex(addr)
    return d & 0xffff

def adc_ReadData(board,cap_len):
        board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x1) # Capture
        board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x0)
        board.dispatch()
        time.sleep(0.0001)
        while True:
            r = board.getNode("daq.chan.csr.stat").read()
            board.getNode("daq.chan.buf.addr").write(0x0)
            d = board.getNode("daq.chan.buf.data").readBlock(cap_len)
            board.dispatch()
            if r & 0x1 == 1:
                break
            print "Crap no capture", hex(slip), hex(tap), hex(r), time.clock()
        if debug:
            for w in d:
                print hex(w) , hex(w & 0x3FF)


def adc_SetTiming(board,chan,slip,tap):

    debug = False
    if debug:
        raw_input("Press enter to set csr.ctrl.chan to "+hex(i_chan))

    board.getNode("csr.ctrl.chan").write(chan) # Talk to correct channel
    board.getNode("daq.chan.csr.ctrl.en_sync").write(0x1) # Enable sync commands
    board.getNode("daq.chan.csr.ctrl.invert").write(0x0) # Don't invert
    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
    board.dispatch()

    swap = 0

    for i_tap in range(tap):

        if debug:
            print "Writing to chan_inc for chan , i_tap = ", i_chan , i_tap
            raw_input("Press enter to continue ")
        board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x1) # Increment tap
        board.getNode("daq.timing.csr.ctrl.chan_inc").write(0x0)
        board.dispatch()


    for i_slip in range(slip):
        if swap == 0:
            swap = 1
            if debug:
                print "Writing to slip_h for chan, i_slip , swap = ", i_chan , i_slip , swap
            board.getNode("daq.timing.csr.ctrl.chan_slip_h").write(0x1) # Increment slip
            board.getNode("daq.timing.csr.ctrl.chan_slip_h").write(0x0)
        else:
            swap = 0
            if debug:
                print "Writing to slip_l for chan , i_slip , swap = ", i_chan , i_slip , swap
            board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x1) # Increment slip
            board.getNode("daq.timing.csr.ctrl.chan_slip_l").write(0x0)
        board.dispatch()

    if debug:
        raw_input("swap. = " +hex(swap)+ " Press enter to continue ")
    board.getNode("daq.chan.csr.ctrl.swap").write(swap)
    board.dispatch()

    board.getNode("daq.chan.csr.ctrl.en_sync").write(0x0) # Disable sync commands
    board.getNode("daq.chan.csr.ctrl.en_buf").write(0x0) # Disable this channel
    board.dispatch()

def adc_Setup(board,slip,tap,patt,chans, debug=True):
    spi = board.getNode("io.spi")
    slaves = [1,2]

    for slave in slaves:

        if debug:
            print "Resetting ADC= ",slave

        spi_config(spi, 0xf, 0x2410, slave) # Divide 31.25MHz ipbus clock by 32; 16b transfer length, auto CSN; Enable SPI slave 0
        spi_write(spi, 0x0, 0x80) # Reset ADC

    for slave in slaves:

        if debug:
            print "Configuring SPI slave = ",slave

        # spi_config(spi, 0xf, 0x2410, slave) # Divide 31.25MHz ipbus clock by 32; 16b transfer length, auto CSN; Enable SPI slave 0

        #    spi_write(spi, 0x1, 0x10) # Sleep
        spi_write(spi, 0x2, 0x05) # 14b 1 lane mode
        csrVal = spi_read(spi,0x2)
        if debug:
            print "Value read back from CSR = ",csrVal

        if patt != None:
            spi_write(spi, 0x3, 0x80 + (patt >> 8)) # Test pattern
            spi_write(spi, 0x4, patt & 0xff) # Test pattern
        else:
            spi_write(spi, 0x3, 0x00) # Disable Test pattern


    board.getNode("daq.timing.csr.ctrl.rst").write(1) # Hold clk40 domain in reset
    board.dispatch()

    board.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
    board.dispatch()


    for i_chan in chans:
    #    raw_input("Press enter to align chanel "+hex(i_chan))
        adc_SetTiming(board,i_chan,slip,tap)

    for i_chan in chans:

        board.getNode("csr.ctrl.chan").write(i_chan) # Talk to correct channel
        board.getNode("daq.chan.csr.ctrl.mode").write(0x1) # Set to capture mode
        board.getNode("daq.chan.csr.ctrl.src").write(0x0) # Set source to ADC
        board.getNode("daq.chan.csr.ctrl.en_sync").write(0x1) # Enable sync commands
        board.getNode("daq.chan.csr.ctrl.invert").write(0x0) # Don't invert
        board.getNode("daq.chan.csr.ctrl.en_buf").write(0x1) # Enable this channel
        board.dispatch()

def adc_checkData(d,patt,debug=True):

    c = 0
    print "length of data block = ", len(d)
    for w in d:
        #if int(w) & 0x3ff == patt:
        if (w & 0x3fff) == patt:
            c += 1

            # Debug....
        if debug:
            print hex(w)
    if debug:
        if c == len(d):
            status = "OK"
        else:
            status = "Bad!"
        print "Test status ( chan, data[0], #pass, status )" , hex(i_chan), hex(d[0] & 0x3fff ) , c , status

def adc_printData(chan,d):
    for w in d:
        print chan, hex(w & 0x3FFF)



#
# -----------------------------------------------------------------------------------
#

debug = True

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://connections.xml")
board = manager.getDevice(sys.argv[1])
board.getClient().setTimeoutPeriod(10000)

v = board.getNode("csr.id").read()
board.dispatch()
print "csr.id = ",v

#patt = 0x0010
#patt = 0x2ABC
#patt = 0x2AAA
#patt = 0x1555
#patt = patt & 0x3FFF # mask off all but bottom 14 bits
patt = None

if patt != None:
    print "Test pattern = ", hex(patt)
else:
    print "No test pattern - taking ADC data"

cap_len = 0x200


debug = True
settings = []
tap = 6
slip = 3


board.getNode("daq.timing.csr.ctrl.rst").write(1) # Hold clk40 domain in reset
board.dispatch()

board.getNode("csr.ctrl.soft_rst").write(1) # Reset ipbus registers
board.dispatch()

time.sleep(1)

chans = range(0x08)

adc_Setup(board,slip,tap,patt,chans)


board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x1) # Capture
board.getNode("daq.timing.csr.ctrl.chan_cap").write(0x0)
board.dispatch()

for i_chan in chans:

    board.getNode("csr.ctrl.chan").write(i_chan) # Talk to correct channel
    board.dispatch()
 
    time.sleep(0.0001)
    while True:
        r = board.getNode("daq.chan.csr.stat").read()
        board.getNode("daq.chan.buf.addr").write(0x0)
        d = board.getNode("daq.chan.buf.data").readBlock(cap_len)
        board.dispatch()
        if r & 0x1 == 1:
            break
        print "Crap no capture", hex(i_chan), hex(r), time.clock()

    if patt != None:
        adc_checkData(d,patt)

    adc_printData(i_chan,d)
