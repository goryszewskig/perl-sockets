
# Tests with TCP KeepAlive

A server and client script for testing tcp keepalive on the server and the client

## server-ka.pl

Start a server and listen for incoming traffic.  Read Only

See ./server-ka.pl --help

## client-ka.pl

Use the client to connect to the server with various TCP KeepAlive values.  Write Only

See ./client-ka.pl --help

## netstat

Use netstat to check for keepalive.

Keepalive will not be set on the LISTEN process, but only on the connections

```text
[root@ora75 keepalive-tests]# netstat -tanelup --timers | grep perl
tcp        0      0 192.168.1.193:4242      0.0.0.0:*               LISTEN      0          1282765    16303/perl           off (0.00/0/0)
tcp        0      0 192.168.1.193:4242      192.168.1.254:4242      ESTABLISHED 0          1282766    16303/perl           keepalive (13.18/0/0)
```


