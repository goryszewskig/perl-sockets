
# Perl TCP Transfer Test

Use Perl sockets to send varying size blocks of data via TCP and get timing.

As see when running client.pl with varying buffer sizes, the buffer size reported by getsockopt() remains constant.

That the buffer size is changing can be seen by comparing the runtimes with varying values for bufsz.


# Usage

## Create Test Data


Create a 10M file of uncompressible test data

```bash
dd if=/dev/urandom  bs=1024 count=20480 | gzip - | dd bs=1024 count=10240 of=testdata-10M.dat

> testdata-100M.dat
```

Now create a 100M file:

```bash
for i in $(seq 1 10)
do
	cat testdata-10M.dat >> testdata-100M.dat
done
```

## server.pl

Set the port with this line near the top of the script

```perl
  my $port = 4242;
```

Then just run the script:

```bash
# ./server.pl
Report Interval: 512
Initial Receive Buffer is 25165824 bytes
Server is now listening ...
Initial Buffer size set to: 2048
```

The script can also be called with a power of 2 integer to set the buffer size:

```bash
#  ./server.pl 4096
Report Interval: 256
Initial Receive Buffer is 425984 bytes
Server is now listening ...
Initial Buffer size set to: 4096
```

## client.pl

Usage for client.pl

```bash
client.pl

usage:  client.pl address port bufsz latency

client.pl --file <filename> --op-line-len N

  --remote-host  The host were server.pl is running
  --port         Port number to connect to - default is 4242
  --local-host   The local IP address to use for the outgoing connection
  --buffer-size  Size of TCP buffer - default is 8192
  --latency      Simulate latency in milliseconds - default is 0
  --h|help       Help

example: client.pl --remote-host 192.168.1.42 --localhost 192.168.1.75 --port 1999 --buffer-size 524288 --latency 24

```

Note: Client and Server cannot run on the same IP address

[Wondershaper](https://github.com/magnific0/wondershaper) was used to throttle the interface associated with 192.168.1.89.

This was to simulate the speed of a slow network connection, such as DSL

as root:

```bash

 wondershaper -a enp4s0 -u 56 -d 56

 ```

 Then run the client:


```bash

bufsz of 128000 is not a power of 2

       remote host: 192.168.1.105
              port: 4242
             bufsz: 128000
 simulated latency: 0

bufsz: 128000
 Send Buffer is 2097152 bytes
Connected to 192.168.1.105 on port 4242
Sending data...

```

Output from server:

```bash

Connection accepted from lestrade3.jks.com : 4242
New Desired Buffer Size set to 128000

Receive Buffer is 425984 bytes
......

Start Time: 1555366187.03162
  End Time: 1555366199.11529
totElapsed: 12.083674


       Packets Received: 1751
         Bytes Received: 7140343
        Avg Packet Size: 4077.87
  Total Elapsed Seconds:  12.083674
Network Elapsed Seconds:  12.051402
   Average milliseconds: 6.882582524
   Avg milliseconds/MiB: 1769.776452413
--------------------------------------------------------------------------------

Socket closed - accepting new connections
```

## packet-test.sh

This script just runs the client with varying size blocks of data

```bash
>  ./packet-test.sh
================================
packet test with 1024 Bytes


       remote host: 192.168.1.56
              port: 4242
             bufsz: 1024
 simulated latency: 5

bufsz: 1024
 Send Buffer is 425984 bytes
Connected to 192.168.1.56 on port 4242
Sending data...
Simulating Latency at 5 milliseconds (5000 microseconds)
================================
packet test with 2048 Bytes


       remote host: 192.168.1.56
              port: 4242
             bufsz: 2048
 simulated latency: 5
...
```

# Examples of differing bufsz

Although the client is reporting the same buffersize via getsockopt(), the effects of changing bufsz can be seen in the following example:


```bash

Connection accepted from poirot.jks.com : 4242
New Desired Buffer Size set to 1024

Receive Buffer is 8388608 bytes
...

Start Time: 1555354723.95825
  End Time: 1555354728.93745
totElapsed: 4.979201


       Packets Received: 969
         Bytes Received: 951296
        Avg Packet Size: 981.73
  Total Elapsed Seconds:   4.979201
Network Elapsed Seconds:   4.971616
   Average milliseconds: 5.130666667
   Avg milliseconds/MiB: 5480.015913886


--------------------------------------------------------------------------------

Socket closed - accepting new connections
Connection accepted from poirot.jks.com : 4242
New Desired Buffer Size set to 2048

Receive Buffer is 8388608 bytes
...

Start Time: 1555354728.96369
  End Time: 1555354733.94296
totElapsed: 4.979274


       Packets Received: 917
         Bytes Received: 1878016
        Avg Packet Size: 2048.00
  Total Elapsed Seconds:   4.979274
Network Elapsed Seconds:   4.967592
   Average milliseconds: 5.417221374
   Avg milliseconds/MiB: 2773.617343511


--------------------------------------------------------------------------------

Socket closed - accepting new connections
Connection accepted from poirot.jks.com : 4242
New Desired Buffer Size set to 4096

Receive Buffer is 8388608 bytes
...

Start Time: 1555354733.97415
  End Time: 1555354738.95864
totElapsed: 4.984485


       Packets Received: 962
         Bytes Received: 3747840
        Avg Packet Size: 3895.88
  Total Elapsed Seconds:   4.984485
Network Elapsed Seconds:   4.967525
   Average milliseconds: 5.163747401
   Avg milliseconds/MiB: 1389.821202186


--------------------------------------------------------------------------------

Socket closed - accepting new connections
Connection accepted from poirot.jks.com : 4242
New Desired Buffer Size set to 8192

Receive Buffer is 8388608 bytes
.....

Start Time: 1555354738.98301
  End Time: 1555354743.96274
totElapsed: 4.979728


       Packets Received: 1518
         Bytes Received: 7454720
        Avg Packet Size: 4910.88
  Total Elapsed Seconds:   4.979728
Network Elapsed Seconds:   4.968118
   Average milliseconds: 3.272805007
   Avg milliseconds/MiB: 698.812202198


--------------------------------------------------------------------------------

Socket closed - accepting new connections
Connection accepted from poirot.jks.com : 4242
New Desired Buffer Size set to 16384

Receive Buffer is 8388608 bytes
........

Start Time: 1555354743.98124
  End Time: 1555354748.96547
totElapsed: 4.984232


       Packets Received: 2134
         Bytes Received: 14483456
        Avg Packet Size: 6787.00
  Total Elapsed Seconds:   4.984232
Network Elapsed Seconds:   4.957092
   Average milliseconds: 2.322910965
   Avg milliseconds/MiB: 358.884488688


--------------------------------------------------------------------------------

Socket closed - accepting new connections
Connection accepted from poirot.jks.com : 4242
New Desired Buffer Size set to 32768

Receive Buffer is 8388608 bytes
........

Start Time: 1555354748.99094
  End Time: 1555354753.96978
totElapsed: 4.978841


       Packets Received: 2212
         Bytes Received: 28278784
        Avg Packet Size: 12784.26
  Total Elapsed Seconds:   4.978841
Network Elapsed Seconds:   4.963040
   Average milliseconds: 2.243688969
   Avg milliseconds/MiB: 184.029293163


--------------------------------------------------------------------------------

Socket closed - accepting new connections
Connection accepted from poirot.jks.com : 4242
New Desired Buffer Size set to 65536

Receive Buffer is 8388608 bytes
..........

Start Time: 1555354753.99502
  End Time: 1555354758.97197
totElapsed: 4.976954


       Packets Received: 2757
         Bytes Received: 56295424
        Avg Packet Size: 20419.09
  Total Elapsed Seconds:   4.976954
Network Elapsed Seconds:   4.961636
   Average milliseconds: 1.799650345
   Avg milliseconds/MiB: 92.416968568


--------------------------------------------------------------------------------

Socket closed - accepting new connections
Connection accepted from poirot.jks.com : 4242
New Desired Buffer Size set to 131072

Receive Buffer is 8388608 bytes
..................

Start Time: 1555354758.99201
  End Time: 1555354763.97448
totElapsed: 4.982475


       Packets Received: 4768
         Bytes Received: 101056512
        Avg Packet Size: 21194.74
  Total Elapsed Seconds:   4.982475
Network Elapsed Seconds:   4.956841
   Average milliseconds: 1.039605914
   Avg milliseconds/MiB: 51.432850843


--------------------------------------------------------------------------------

Socket closed - accepting new connections

```

## packet-driver.sh

Assuming there are multiple interfaces setup for testing different MTU sizes

```bash
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

```

## packet-averages.pl

You may wish to run several tests and get some averages from the server side.

Start the server like this:

```bash
$ ./server.pl | tee mtu-9000.log
```

Then the client in a loop via `packet-driver.sh`.


Then get the averages from the resulting log file on the server side:

```text
root@ubuntu-mule-02# ./packet-averages.pl < mtu-1500.log
key/avg:          Bytes Received 1073733637.000000
key/avg:         Avg Packet Size       7898.147391
key/avg:        Packets Received     135948.304348
key/avg:    Average milliseconds          0.043824
key/avg:    Avg Megabytes/Second        172.000000
key/avg:    Avg milliseconds/MiB          5.818500
key/avg:   Total Elapsed Seconds          6.850447
key/avg: Network Elapsed Seconds          5.958098
```




