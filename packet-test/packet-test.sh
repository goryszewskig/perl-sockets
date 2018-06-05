#!/bin/bash

for bufsz in 1024 2048 4096 8192 16384 32768 65536 131072 
do
	echo "================================"
	echo packet test with $bufsz Bytes
	./client.pl $bufsz
done

