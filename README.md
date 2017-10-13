
This repository contains readout firmware and test software for the SOLID experiment

Current version is v8 (clone from tags/v8)

The master firmware uses the [ipbb](https://github.com/ipbus/ipbb) build tool, and requires the ipbus system firmware.
The following example procedure should build a board image for the 64 channel readout board. Note that a reasonably up-to-date
operating system (e.g. Centos7) is required.

	mkdir work
	cd work
	curl -L https://github.com/ipbus/ipbb/archive/v0.2.3.tar.gz | tar xvz
	source ipbb-0.2.3/env.sh
	ipbb init build
	cd build
	ipbb add git https://github.com/ipbus/ipbus-firmware.git -b ipbus_2_0_v1
	ipbb add git https://your_id@bitbucket.org/solidexperiment/solid_firmware.git -b v8
	ipbb proj create vivado 64chan solid_firmware:projects/64chan_test
	cd proj/64chan
	ipbb vivado project
	ipbb vivado impl
	ipbb vivado bitfile
	ipbb vivado package

### Who do I talk to? ###

* Dave Newbold (dave.newbold@cern.ch)
* Nick Ryder (nick.ryder@physics.ox.ac.uk)
* David Cussans (david.cussans@bristol.ac.uk)

# UHAL install
See http://ipbus.web.cern.ch/ipbus/doc/user/html/software/installation.html