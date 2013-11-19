#!/bin/bash

#
# Copyright (C) 2013 Dan Fruehauf <malkodan@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

######################
# CORE FUNCTIONALITY #
######################

###########
# MODULES #
###########

########
# L2TP #
########

###########
# OPENVPN #
###########

########
# PPTP #
########

#######
# SSH #
#######
# test argument parsing
test_ssh_argument_parsing() {
	source check_vpn_plugins/ssh.sh
	local arguments="-p 5009 -o LogLevel=Debug -o Host=test.example.com"
	local -i port=`_ssh_parse_option -p Port $arguments`
	assertTrue "parsing port" \
		"[ $port -eq 5009 ]"

	local log_level=`_ssh_parse_option UNUSED LogLevel $arguments`
	assertTrue "parsing LogLevel" \
		"[ x$log_level = xDebug ]"

	local host=`_ssh_parse_option UNUSED Host $arguments`
	echo $host
	assertTrue "parsing Host" \
		"[ x$host = xtest.example.com ]"
}

# test device prefix Tunnel=ethernet
test_ssh_device_prefix_ethernet() {
	source check_vpn_plugins/ssh.sh
	local device_prefix=`_ssh_parse_device_prefix -o Tunnel=ethernet`
	assertTrue "device prefix (Tunnel=ethernet)" \
		"[ x$device_prefix = xtap ]"
}

# test device prefix Tunnel=point-to-point
test_ssh_device_prefix_ptp() {
	source check_vpn_plugins/ssh.sh
	local device_prefix=`_ssh_parse_device_prefix -o Tunnel=point-to-point`
	assertTrue "device prefix (Tunnel=point-to-point)" \
		"[ x$device_prefix = xtun ]"
}

# test ssh integration
test_ssh_vpn_integration() {
	_test_root || return

	local -i retval=0
	./check_vpn -t ssh -H 115.146.95.248 -u root -p uga -d tun1
	retval=$?

	assertTrue "ssh vpn connection" \
		"[ $retval -eq 0 ]"
}

####################
# COMMON FUNCTIONS #
####################
_test_root() {
	assertTrue "test running as root" "[ `id -u` -eq 0 ]"
}

##################
# SETUP/TEARDOWN #
##################

oneTimeSetUp() {
	true
}

oneTimeTearDown() {
	true
}

setUp() {
	true
}

tearDown() {
	true
}

# load and run shUnit2
. /usr/share/shunit2/shunit2
