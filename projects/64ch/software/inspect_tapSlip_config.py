import dataset

db = dataset.connect('mysql://DAQGopher:gogogadgetdatabase@localhost/solid_phase1_running')
nChanJumps = 0
iEntry = -1
prevChan = 64
min_tap, max_tap, min_slip, max_slip = 99, 99, 99, 99
print 'Channel, slip, tap'
for entry in db['TapSlips']: 
    if entry['ip'] == '51': 
        print entry['channel'], entry['slip'], entry['tap']        

    '''
    if entry['configID'] == 26:
        if prevChan != entry['channel'] - 1:
            #print entry
            nChanJumps += 1 
        
        iEntry += 1
        if iEntry == 0 or entry['tap'] > max_tap: max_tap = entry['tap']
        if iEntry == 0 or entry ['tap'] < min_tap: min_tap = entry['tap']
        if iEntry == 0 or entry ['slip'] > max_slip: max_slip = entry['slip']
        if iEntry == 0 or entry ['slip'] < min_slip: min_slip = entry['slip']
        prevChan = entry['channel']

print 'Current (max) config ID:', max(db['Config']['configID'])
print 'nJumps:', nChanJumps
print 'max/min tap:', max_tap, min_tap
print 'max/min slip:', max_slip, min_slip
'''
