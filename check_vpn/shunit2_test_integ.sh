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

# integration tests for check_vpn

########
# L2TP #
########
# test l2tp integration
test_l2tp_vpn_integration() {
	_test_root || return

	local -i retval=0
	local username=root
	local password=`pwmake $RANDOM`
	local tmp_output=`mktemp`

	# setup the vpn server, using ssh :)
	ssh root@$VPN_SERVER_L2TP "echo '$username * $password *' > /etc/ppp/chap-secrets"

	$CHECK_VPN -l -t l2tp -H $VPN_SERVER_L2TP -u $username -p $password -d ppp6 -- noccp > $tmp_output
	retval=$?

	assertTrue "l2tp vpn connection" \
		"[ $retval -eq 0 ]"

	local expected_string="OK: VPN to '$VPN_SERVER_L2TP' up and running on 'ppp6', 'http://www.google.com' reachable"
	local output=`cut -d\| -f1 $tmp_output`
	assertTrue "l2tp vpn connection output" \
		"[ x'$output' = x'$expected_string' ]"

	rm -f $tmp_output
}

###########
# OPENVPN #
###########
# test l2tp integration
test_openvpn_vpn_integration() {
	_test_root || return

	local -i retval=0
	local username=root
	local password=`pwmake $RANDOM`
	local tmp_output=`mktemp`
	local tmp_server_cert=`mktemp`

	# setup the vpn server, using ssh :)
	ssh root@$VPN_SERVER_OPENVPN \
		"echo '$username' > /etc/openvpn/passwd && echo '$password' >> /etc/openvpn/passwd"

	# get server certificate
	scp root@$VPN_SERVER_OPENVPN:/etc/openvpn/ca.crt $tmp_server_cert > /dev/null
	retval=$?
	assertTrue "openvpn vpn server certificate copy" \
		"[ $retval -eq 0 ]"

	$CHECK_VPN -l -t openvpn -H $VPN_SERVER_PPTP -u $username -p $password -d tun91 -- --ca $tmp_server_cert --proto tcp --cipher AES-256-CBC --comp-lzo > $tmp_output
	retval=$?

	assertTrue "openvpn vpn connection" \
		"[ $retval -eq 0 ]"

	local expected_string="OK: VPN to '$VPN_SERVER_PPTP' up and running on 'tun91', 'http://www.google.com' reachable"
	local output=`cut -d\| -f1 $tmp_output`
	assertTrue "openvpn vpn connection output" \
		"[ x'$output' = x'$expected_string' ]"

	rm -f $tmp_output $tmp_server_cert
}

########
# PPTP #
########
# test pptp integration
test_pptp_vpn_integration() {
	_test_root || return

	local -i retval=0
	local username=root
	local password=`pwmake $RANDOM`
	local tmp_output=`mktemp`

	# setup the vpn server, using ssh :)
	ssh root@$VPN_SERVER_PPTP "echo '$username * $password *' > /etc/ppp/chap-secrets"

	$CHECK_VPN -l -t pptp -H $VPN_SERVER_PPTP -u $username -p $password -d ppp40 -- require-mppe-128 refuse-pap refuse-eap refuse-chap refuse-mschap novj novjccomp nobsdcomp > $tmp_output
	retval=$?

	assertTrue "pptp vpn connection" \
		"[ $retval -eq 0 ]"

	local expected_string="OK: VPN to '$VPN_SERVER_PPTP' up and running on 'ppp40', 'http://www.google.com' reachable"
	local output=`cut -d\| -f1 $tmp_output`
	assertTrue "pptp vpn connection output" \
		"[ x'$output' = x'$expected_string' ]"

	rm -f $tmp_output
}

#######
# SSH #
#######
# test ssh integration
test_ssh_vpn_integration() {
	_test_root || return

	local -i retval=0
	local tmp_output=`mktemp`

	./check_vpn -l -t ssh -H $VPN_SERVER_SSH -u root -p uga -d tun1 > $tmp_output
	retval=$?

	assertTrue "ssh vpn connection" \
		"[ $retval -eq 0 ]"

	local expected_string="OK: VPN to '$VPN_SERVER_PPTP' up and running on 'tun1', 'http://www.google.com' reachable"
	local output=`cut -d\| -f1 $tmp_output`
	assertTrue "ssh vpn connection output" \
		"[ x'$output' = x'$expected_string' ]"

	rm -f $tmp_output
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
	CHECK_VPN=`dirname $0`/check_vpn

	VPN_SERVER_L2TP=115.146.95.248
	VPN_SERVER_OPENVPN=115.146.95.248
	VPN_SERVER_PPTP=115.146.95.248
	VPN_SERVER_SSH=115.146.95.248
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
