import time
import uhal
from I2CuHal import I2CCore
import StringIO
import csv


class si5344:

    def __init__(self, i2c, slaveaddr=0x68):
        self.i2c = i2c
        self.slaveaddr = slaveaddr

    def readRegister(self, myaddr, nwords):
        currentPg = self.getPage()
        requirePg = (myaddr & 0xFF00) >> 8
        if currentPg[0] != requirePg:
            self.setPage(requirePg)
        self.i2c.write(self.slaveaddr, [myaddr], False)
        return self.i2c.read(self.slaveaddr, nwords)

    def writeRegister(self, myaddr, data):
        myaddr = myaddr & 0xFFFF
        currentPg = self.getPage()
        requirePg = (myaddr & 0xFF00) >> 8
        if currentPg[0] != requirePg:
            self.setPage(requirePg)
        data.insert(0, myaddr)
        self.i2c.write(self.slaveaddr, [myaddr])

    def setPage(self, page):
        myaddr = [0x01, page]
        self.i2c.write(self.slaveaddr, [0x01, page], True)

    def getPage(self):
        self.i2c.write(self.slaveaddr, [0x01], False)
        return self.i2c.read(self.slaveaddr, 1)

    def getDeviceVersion(self):
        self.setPage(0)
        self.i2c.write(self.slaveaddr, [0x02], False)
        return self.i2c.read(self.slaveaddr, 2)

    def parse_clk(self, filename):
        deletedcomments = """"""
        with open(filename, 'rb') as configfile:
            for i, line in enumerate(configfile):
                if not line.startswith('#'):
                    if not line.startswith('Address'):
                        deletedcomments += line
        csvfile = StringIO.StringIO(deletedcomments)
        cvr = csv.reader(csvfile, delimiter=',', quotechar='|')
        regSettingList = list(cvr)
        return regSettingList

    def writeConfiguration(self, regSettingList):
        for item in regSettingList:
            self.writeRegister(item[0], [item[1]])
        for item in regSettingList:
            d = self.readRegister(item[0])
            if item[1] != int(d):
                print "Config error", hex(item[0]), hex(item[1]), hex(d)
