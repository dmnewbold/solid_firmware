from I2CuHal import I2CCore
import StringIO
import csv

class si5326:
    #Class to configure the Si5326 clock generator

    def __init__(self, i2c, slaveaddr=0x68):
        self.i2c = i2c
        self.slaveaddr = slaveaddr

    def readRegister(self, myaddr, nwords):
        self.i2c.write(self.slaveaddr, myaddr, False)
        return self.i2c.read(self.slaveaddr, nwords)

    def writeRegister(self, myaddr, data):
        data.insert(0, myaddr)
        self.i2c.write(self.slaveaddr, data, True)

    def getDeviceVersion(self):
        # Read registers containing chip information
        self.i2c.write(self.slaveaddr, 0x86, False)
        res = self.i2c.read(self.slaveaddr, 2)
        print "Si5326 partnum registers:"
        result="\t  "
        for iaddr in res:
            result+="%#02x "%(iaddr)
        print result
        return res

    def parse_clk(self, filename):
        #Parse the configuration file produced by Silicon Labs horrible software
    	deletedcomments=""""""
    	print "Parsing Si5326 config file:", filename
    	with open(filename, 'rb') as configfile:
    		for i, line in enumerate(configfile):
    		    if not line.startswith('#') :
    		      if not line.startswith('Address'):
    			deletedcomments+=line
    	csvfile = StringIO.StringIO(deletedcomments)
    	cvr = csv.reader(csvfile, delimiter=',', quotechar='|')
        regSettingList = list(cvr)
        print "\t  ", len(regSettingList), "elements"
        return regSettingList

	def writeConfiguration(self, regSettingList):
		print "Writing Si5326 configuration:"
		for item in regSettingList:
			regAddr = int(item[0], 16)
			regData = [int(item[1], 16)]
			self.writeRegister(regAddr, regData)
		print "Verifying Si5326 config:"
		for item in regSettingList:
			regAddr = int(item[0], 16)
			regData = [int(item[1], 16)]
			self.readRegister(regAddr, d, 1)
            
