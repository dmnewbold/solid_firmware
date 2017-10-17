import dataset

db = dataset.connect('mysql://DAQGopher:gogogadgetdatabase@localhost/solid_phase1_running')
for entry in db['TapSlips']: print entry

print max(db['Config']['configID'])
