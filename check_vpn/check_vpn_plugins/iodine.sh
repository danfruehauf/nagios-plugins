#!/bin/bash

#
# iodine - iodine plugin for check_vpn
# Copyright (C) 2013 Dan Fruehauf <malkoadan@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

##############
### IODINE ###
##############
declare -r IODINE_DEVICE_PREFIX=dns

# returns a free vpn device
# $1 - device prefix
_iodine_allocate_vpn_device() {
	local device_prefix=$1; shift
	allocate_vpn_device $device_prefix
}

# returns the vpn devices for the given lns
# $1 - lns
_iodine_vpn_device() {
	local lns=$1; shift
	local pids=`_iodine_get_pids $lns`
	local pid
	for pid in $pids; do
		if ps -p $pid --no-header -o cmd | grep -q "\b-r $lns\b"; then
			local iodine_command_line=`ps -p $pid --no-header -o cmd`
			local device=`echo $iodine_command_line | grep -o "\b-d $IODINE_DEVICE_PREFIX[[:digit:]]\+:" | cut -d' ' -f2 | cut -d: -f1`
			devices="$devices $device"
		fi
	done
	echo "$devices"
}

# initiate a iodine connection
# $1 - lns - where to connect to
# $2 - username
# $3 - password
# $4 - device
# "$@" - extra options
_iodine_start_vpn() {
	local lns=$1; shift
	local username=$1; shift
	local password=$1; shift
	local device=$1; shift

	local -i retval=0
	local tmp_output=`mktemp`

	if ! which iodine >& /dev/nulll; then
		ERROR_STRING="Error: iodine not installed"
		return 1
	fi

	echo "$password" | iodine -r $lns $username -d $device "$@" >& $tmp_output
	retval=$?

	if [ $retval -ne 0 ]; then
		ERROR_STRING=`tail -1 $tmp_output`
		rm -f $tmp_output
		return 1
	fi

	rm -f $tmp_output
	return 0
}

# stops the vpn
# $1 - lns
# $2 - vpn device (optional)
_iodine_stop_vpn() {
	local lns=$1; shift
	local device=$1; shift
	if [ x"$lns" = x ]; then
		echo "lns unspecified, can't kill iodine" 1>&2
		return 1
	fi
	local pids=`_iodine_get_pids $lns $device`
	if [ x"$pids" != x ]; then
		kill $pids
	fi
}

# returns a list of iodine pids
# $1 - lns
# $2 - vpn device (optional)
_iodine_get_pids() {
	local lns=$1; shift
	local device=$1; shift
	local iodine_pids=`pgrep iodine | xargs`
	local iodine_relevant_pids
	for pid in $iodine_pids; do
		if ps -p $pid --no-header -o cmd | grep -q " -r $lns\b"; then
			if [ x"$device" != x ]; then
				if ps -p $pid --no-header -o cmd | grep -q " -d $device\b"; then
					iodine_relevant_pids="$iodine_relevant_pids $pid"
				fi
			else
				iodine_relevant_pids="$iodine_relevant_pids $pid"
			fi
		fi
	done
	echo $iodine_relevant_pids
}

# return true if VPN is up, false otherwise...
# $1 - lns
# $2 - vpn device (optional)
_iodine_is_vpn_up() {
	local lns=$1; shift
	local device=$1; shift
	ifconfig $device >& /dev/null && \
		ip addr show dev $device | grep -q "\binet\b"
}

