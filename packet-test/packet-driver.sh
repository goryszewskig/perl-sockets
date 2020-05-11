#!/usr/bin/env bash

declare -A localHosts
declare -A remoteHosts

localHosts[9000]=192.168.154.4
localHosts[1500]=192.168.199.35

remoteHosts[9000]=192.168.154.5
remoteHosts[1500]=192.168.199.36

blocksize=8192
testfile=testdata-1G.dat

mtu=9000

for i in {0..22}
do
	cmd="./client.pl --remote-host ${remoteHosts[$mtu]} --local-host ${localHosts[$mtu]} --file $testfile --buffer-size $blocksize"
	echo "executing: $cmd"
	$cmd
done

