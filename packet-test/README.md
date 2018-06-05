

<h3>Perl TCP Transfer Test</h3>

Use Perl sockets to send varying size blocks of data via TCP and get timing.

Though the scripts to vary the size of the data per send() call, I have not been able to influence the TCP buffer size.

While server.pl and  client.pl use setsockopt() to set the TCP buffer size, there does not seem to be any method that actually works.

The buffer size reported by getsockopt() remains constant regardless of attempts to change it

<h3>Usage</h3>

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

# server.pl

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

# client.pl

Set the target server and port at the top of the script
Note: Client and Server cannot run on the same IP address

```perl
my $remote = 'my.server.org';
my $port = 4242;
```
Then the client can be run with a buffer size:

```bash
>  ./client.pl 16384
Send Buffer is 425983 bytes
Connected to 192.168.0.128 on port 4242
```

Output from server:

```bash
Connection accepted from c-76-115-6-154.hsd1.or.comcast.net : 4242
New Desired Buffer Size set to 16384

Receive Buffer is 25165824 bytes
Report Interval: 64
..........

Start Time: 1528240098.82339
End Time: 1528240105.84435
totElapsed: 7.020959


Packets Received: 640
Bytes Received: 10485760
Total Elapsed Seconds:   7.020959
Network Elapsed Seconds:   7.000175
Average milliseconds: 10.937773438
Avg milliseconds/MiB: 700.017500000

--------------------------------------------------------------------------------

Socket closed - accepting new connections

```

The default for client.pl is a 2048 byte buffer size

```bash
>  ./client.pl
Send Buffer is 425984 bytes
Connected to 192.168.0.128 on port 4242
```

Output from server:

```bash
Connection accepted from c-76-115-6-154.hsd1.or.comcast.net : 4242
New Desired Buffer Size set to 2048

Receive Buffer is 25165824 bytes
Report Interval: 512
..........

Start Time: 1528240182.93132
End Time: 1528240189.96185
totElapsed: 7.030534

Packets Received: 5120
Bytes Received: 10485760
Total Elapsed Seconds:   7.030534
Network Elapsed Seconds:   6.972060
Average milliseconds: 1.361730469
Avg milliseconds/MiB: 697.206000000

--------------------------------------------------------------------------------

Socket closed - accepting new connections
```

# packet-test.sh

This script just runs the client with varying size blocks of data

```bash
>  ./packet-test.sh
================================
packet test with 1024 Bytes
Send Buffer is 425984 bytes
Connected to 192.168.157.128 on port 4242
================================
packet test with 2048 Bytes
Send Buffer is 425984 bytes
Connected to 192.168.157.128 on port 4242
...
```

