
This repository contains readout firmware and test software for the SOLID experiment. This is a branch aimed at getting the 8 channel board working

This is branch v19_8chan_01 ( branched from v19)

The master firmware uses the [ipbb](https://github.com/ipbus/ipbb) build tool, and requires the ipbus system firmware.
The following example procedure should build a board image for the 64 channel readout board. Note that a reasonably up-to-date
operating system (e.g. Centos7) is required.

	mkdir work
	cd work
	curl -L https://github.com/ipbus/ipbb/archive/v0.2.3.tar.gz | tar xvz
	source ipbb-0.2.3/env.sh
	ipbb init build
	cd build
	ipbb add git https://github.com/ipbus/ipbus-firmware.git -b enhancement/46
	ipbb add git https://your_id@bitbucket.org/solidexperiment/solid_firmware.git -b v19_8chan_01
	ipbb proj create vivado 8chan solid_firmware:projects/8ch
	cd proj/8chan
	ipbb vivado project
	ipbb vivado impl
	ipbb vivado bitfile
	ipbb vivado package

### Who do I talk to? ###

* David Cussans (david.cussans@bristol.ac.uk)
* Dave Newbold (dave.newbold@cern.ch) ( original firmware author )


# UHAL install
See http://ipbus.web.cern.ch/ipbus/doc/user/html/software/installation.html