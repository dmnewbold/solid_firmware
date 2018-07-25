import os
import dataset
import sys
import pickle

sys.path.append('/home/dsaunder/workspace/go_projects/src/bitbucket.org/solidexperiment/readout-software/scripts/')
import detector_config_tools
ips = detector_config_tools.currentIPs(False)
'''
for ip in ips:
    cmd = "python align_sdr.py " + str(ip) + " output_" + str(ip) + ".tapslips"
    print cmd
    try:
        os.system(cmd)
    except:
        sys.exit(0)

'''
# Dump into a db
db = dataset.connect('mysql://DAQGopher:gogogadgetdatabase@localhost/solid_phase1_running')
configID = 0 #first time case
if len(db['TapSlips']) != 0: configID = max(db['TapSlips']['configID'])['configID'] + 1

print 'New config ID:', configID
for ip in ips:
    results = pickle.load( open( "alignment_31Jan/output_" + str(ip) + ".tapslips", "rb" ) )
    for res in results:
        db['TapSlips'].insert({'configID': int(configID), 'ip': str(ip), 'tap': res[2], 'slip': res[1], 'channel': res[0]})
