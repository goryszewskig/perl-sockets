#!/usr/bin/env bash

: ${1:?Call with 'packet-driver.sh <SIZE>'!}
: ${mtu:=$1}

if ( echo $mtu | grep -vE '1500|9000' ); then
	echo Please use 1500 or 9000
	exit 1
fi

#echo "MTU: $mtu"

declare -A localHosts
declare -A remoteHosts

localHosts[9000]=192.168.154.4
localHosts[1500]=192.168.199.35

remoteHosts[9000]=192.168.154.5
remoteHosts[1500]=192.168.199.36

blocksize=8192
testfile=testdata-1G.dat

cmd="./client.pl --remote-host ${remoteHosts[$mtu]} --local-host ${localHosts[$mtu]} --file $testfile --buffer-size $blocksize"

for i in {0..22}
do
	echo "executing: $cmd"
	$cmd
done
