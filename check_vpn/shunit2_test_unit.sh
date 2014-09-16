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
# test check_open_port, unreachable host
test_check_open_port_unresolvable() {
	source $CHECK_VPN
	check_open_port some.domain.that.doesnt.exist.com 1111 >& /dev/null
	assertFalse "host unresolvable" \
		"[ $? -eq 0 ]"
}

# test check_open_port
test_check_open_port_filtered() {
	source $CHECK_VPN
	check_open_port www.google.com 1111 >& /dev/null
	assertFalse "port filtered" \
		"[ $? -eq 0 ]"
}

# test check_open_port, filtered port
test_check_open_port_closed() {
	source $CHECK_VPN
	check_open_port localhost 1111 >& /dev/null
	assertFalse "port closed" \
		"[ $? -eq 0 ]"
}

# test check_open_port
test_check_open_port_open() {
	source $CHECK_VPN
	check_open_port www.google.com 80 >& /dev/null
	assertTrue "port open" \
		"[ $? -eq 0 ]"
}

# test the is_specific_device function
test_is_specific_device() {
	source $CHECK_VPN

	assertTrue  "tun1:   specific" "is_specific_device tun1"
	assertTrue  "tap10:  specific" "is_specific_device tap10"
	assertTrue  "ppp250: specific" "is_specific_device ppp250"

	assertFalse "tun:    specific" "is_specific_device tun"
	assertFalse "tap:    specific" "is_specific_device tap"
	assertFalse "ppp:    specific" "is_specific_device ppp"
	assertFalse "ttt20:  specific" "is_specific_device ttt20"
	assertFalse "ttt:    specific" "is_specific_device ttt"
}

# test check_vpn locking
test_lock_check_vpn() {
	source $CHECK_VPN

	# mock CHECK_VPN_LOCK
	export CHECK_VPN_LOCK=`mktemp -d -u`
	assertFalse "lock doesn't exists" "test -d $CHECK_VPN_LOCK"
	lock_check_vpn
	assertTrue "lock exists" "test -d $CHECK_VPN_LOCK"
	rmdir $CHECK_VPN_LOCK
}

# test check_vpn locking
test_unlock_check_vpn() {
	source $CHECK_VPN

	# mock CHECK_VPN_LOCK
	export CHECK_VPN_LOCK=`mktemp -d`
	assertTrue "lock exists" "test -d $CHECK_VPN_LOCK"
	unlock_check_vpn
	assertFalse "lock doesn't exists" "test -d $CHECK_VPN_LOCK"
}

# test routing table used for device
test_routing_table_for_device() {
	source $CHECK_VPN
	local -i routing_table

	routing_table=`get_routing_table_for_device tap101`
	assertTrue "routing table for tap101" "[ $routing_table -eq 2101 ]"

	routing_table=`get_routing_table_for_device tun32`
	assertTrue "routing table for tun32" "[ $routing_table -eq 3032 ]"

	routing_table=`get_routing_table_for_device ppp250`
	assertTrue "routing table for ppp250" "[ $routing_table -eq 4250 ]"

	routing_table=`get_routing_table_for_device crapper1020`
	assertTrue "routing table for crapper1020" "[ $routing_table -eq 6020 ]"
}

###########
# MODULES #
###########

########
# L2TP #
########
# allocate device for l2tp
test_l2tp_allocate_vpn_device() {
	source check_vpn_plugins/l2tp.sh

	local device=`_l2tp_allocate_vpn_device`
	assertTrue "allocate l2tp device" "[ x$device = x'ppp0' ]"
}

# test _l2tp_generate_ppp_options
test_l2tp_generate_ppp_options() {
	source check_vpn_plugins/l2tp.sh

	local tmp_ppp_options=`mktemp`
	local tmp_ppp_options_expected=`mktemp`

	_l2tp_generate_ppp_options \
		l2tp.vpn.com my-username my-password ppp140 \
		require-mppe-128,require-mschapv2 > $tmp_ppp_options

cat > $tmp_ppp_options_expected <<EOF
user my-username
password my-password
unit 140
lock
noauth
nodefaultroute
noipdefault
debug
require-mppe-128
require-mschapv2
EOF

	local -i diff_lines=`diff -urN $tmp_ppp_options $tmp_ppp_options_expected | wc -l`
	assertTrue "ppp options not same as expected" "[ $diff_lines -eq 0 ]"

	rm -f $tmp_ppp_options $tmp_ppp_options_expected
}

# test _l2tp_generate_xl2tpd_options
test_l2tp_generate_xl2tpd_options() {
	source check_vpn_plugins/l2tp.sh

	local tmp_l2tp_options=`mktemp`
	local tmp_l2tp_options_expected=`mktemp`

	_l2tp_generate_xl2tpd_options \
		/tmp/ppp-options l2tp.vpn.com \
		my-username my-password ppp140 > $tmp_l2tp_options

cat > $tmp_l2tp_options_expected <<EOF
[global]
port = 0
access control = no
[lac /tmp/ppp-options]
name = /tmp/ppp-options
lns = /tmp/ppp-options
pppoptfile = ppp140
ppp debug = yes
require authentication = yes
require chap = yes
length bit = yes
EOF

	local -i diff_lines=`diff -urN $tmp_l2tp_options $tmp_l2tp_options_expected | wc -l`
	assertTrue "l2tp options not same as expected" "[ $diff_lines -eq 0 ]"

	rm -f $tmp_l2tp_options $tmp_l2tp_options_expected
}

###########
# OPENVPN #
###########
# allocate device for openvpn
test_openvpn_allocate_vpn_device() {
	source check_vpn_plugins/openvpn.sh

	local device=`_openvpn_allocate_vpn_device tap`
	assertTrue "allocate openvpn tap device" "[ x$device = x'tap0' ]"

	local device=`_openvpn_allocate_vpn_device tun`
	assertTrue "allocate openvpn tun device" "[ x$device = x'tun0' ]"
}

# test argument parsing
test_openvpn_argument_parsing() {
	source check_vpn_plugins/openvpn.sh
	local arguments="--port 1194 --proto tcp --ca /etc/openvpn/ca.crt --config /etc/openvpn/vpn.com.conf"

	local -i port=`_openvpn_parse_arg_from_extra_options port $arguments`
	assertTrue "parsing port" \
		"[ $port -eq 1194 ]"

	local proto=`_openvpn_parse_arg_from_extra_options proto $arguments`
	assertTrue "parsing proto" \
		"[ x$proto = x'tcp' ]"

	local ca=`_openvpn_parse_arg_from_extra_options ca $arguments`
	assertTrue "parsing ca" \
		"[ x$ca = x'/etc/openvpn/ca.crt' ]"

	local config=`_openvpn_parse_arg_from_extra_options config $arguments`
	assertTrue "parsing config" \
		"[ x$config = x'/etc/openvpn/vpn.com.conf' ]"
}

########
# PPTP #
########
# allocate device for pptp
test_pptp_allocate_vpn_device() {
	source check_vpn_plugins/pptp.sh

	local device=`_pptp_allocate_vpn_device`
	assertTrue "allocate pptp device" "[ x$device = x'ppp0' ]"
}

#######
# SSH #
#######
# allocate device for ssh
test_ssh_allocate_vpn_device() {
	source check_vpn_plugins/ssh.sh

	local device=`_ssh_allocate_vpn_device tap`
	assertTrue "allocate ssh tap device" "[ x$device = x'tap0' ]"

	local device=`_ssh_allocate_vpn_device tun`
	assertTrue "allocate ssh tun device" "[ x$device = x'tun0' ]"
}

# test argument parsing
test_ssh_argument_parsing() {
	source check_vpn_plugins/ssh.sh
	local arguments="-p 5009 -o LogLevel=Debug -o Host=test.example.com"

	local -i port=`_ssh_parse_option -p Port $arguments`
	assertTrue "parsing port" \
		"[ $port -eq 5009 ]"

	local log_level=`_ssh_parse_option UNUSED LogLevel $arguments`
	assertTrue "parsing LogLevel" \
		"[ x$log_level = x'Debug' ]"

	local host=`_ssh_parse_option UNUSED Host $arguments`
	assertTrue "parsing Host" \
		"[ x$host = x'test.example.com' ]"
}

# test device prefix Tunnel=ethernet
test_ssh_device_prefix_ethernet() {
	source check_vpn_plugins/ssh.sh
	local device_prefix=`_ssh_parse_device_prefix -o Tunnel=ethernet`
	assertTrue "device prefix (Tunnel=ethernet)" \
		"[ x$device_prefix = x'tap' ]"
}

# test device prefix Tunnel=point-to-point
test_ssh_device_prefix_ptp() {
	source check_vpn_plugins/ssh.sh
	local device_prefix=`_ssh_parse_device_prefix -o Tunnel=point-to-point`
	assertTrue "device prefix (Tunnel=point-to-point)" \
		"[ x$device_prefix = x'tun' ]"
}

##################
# SETUP/TEARDOWN #
##################

oneTimeSetUp() {
	CHECK_VPN=`dirname $0`/check_vpn
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
