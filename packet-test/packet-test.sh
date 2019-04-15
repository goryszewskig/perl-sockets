#!/bin/bash

localHost=192.168.1.254
serverHost=192.168.1.56
port=4242
timeoutSeconds=5
latency=5

for bufsz in 1024 2048 4096 8192 16384 32768 65536 131072 
do
	echo "================================"
	echo packet test with $bufsz Bytes
	timeout $timeoutSeconds ./client.pl --remote-host $serverHost --local-host $localHost --port $port --buffer-size $bufsz --latency $latency
done

