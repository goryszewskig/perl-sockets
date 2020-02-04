#!/usr/bin/env perl

=head1 server.pl

 Though this code ( and client.pl ) use setsockopt() to set the TCP buffer size,
 there does not seem to be any method that actually works.

 The buffer size reported by getsockopt() remains constant regardless of attempts to change it

 Use netstat to check for keepalive.

 Keepalive will not be set on the LISTEN process, but only on the connections
 
 [root@ora75 keepalive-tests]# netstat -tanelup --timers | grep perl
 tcp        0      0 192.168.1.193:4242      0.0.0.0:*               LISTEN      0          1282765    16303/perl           off (0.00/0/0)
 tcp        0      0 192.168.1.193:4242      192.168.1.254:4242      ESTABLISHED 0          1282766    16303/perl           keepalive (13.18/0/0)


=cut

use warnings;
use strict;
no strict qw( subs ); # hack for old perl version
use IO::Socket::INET;

BEGIN {
	# Note: TCP_USER_TIMEOUT is available as of Linux Kernel 2.6.37 - see 'man tcp'
	eval {
		require Socket;
		Socket->import( qw(
			SOL_SOCKET SO_SNDBUF SO_KEEPALIVE IPPROTO_IP 
			IP_TTL TCP_KEEPIDLE TCP_KEEPINTVL TCP_KEEPCNT 
			IPPROTO_TCP TCP_USER_TIMEOUT) 
		);
	};
	
	# hack for old versions of Socket.pm that do not have TCP_KEEP* values or TCP_USER_TIMEOUT
	if ($@) {
		
		warn "Old Perl Version - setting TCP_KEEP constants manually\n";
		warn "Upgrade Socket.pm to correct this\n";

		# values are found in /usr/include/netinet/tcp.h

		use Socket qw(SOL_SOCKET SO_SNDBUF SO_KEEPALIVE IPPROTO_IP IP_TTL IPPROTO_TCP);
		*Socket::TCP_KEEPIDLE = sub { 4 };
		*Socket::TCP_KEEPINTVL = sub { 5 };
		*Socket::TCP_KEEPCNT = sub { 6 };
		*Socket::TCP_USER_TIMEOUT = sub { 18 };
	}
}


use Getopt::Long;
use Time::HiRes qw(gettimeofday tv_interval);
#use Data::Dumper;

sub usage;

my $port=4242;
my $bufsz=8192;
my ($tcpKeepAlive,$tcpIdle,$tcpInterval,$tcpCount,$tcpUserTimeout) = (0,0,0,0,0);
my $localHost = '';
my $help=undef;

$| = 1; # flush stdout
 
GetOptions (
	"local-host=s" => \$localHost,
	"port=i" => \$port,
	"buffer-size=i" => \$bufsz,
	"keepalive!" => \$tcpKeepAlive,
	"tcp-idle=i" => \$tcpIdle,
	"tcp-interval=i" => \$tcpInterval,
	"tcp-count=i" => \$tcpCount,
	"tcp-user-timeout=i" => \$tcpUserTimeout,
	"h|help!" => \$help,
) or die usage(1);


if ($help) {
	usage;
	exit;
}

# bufsz really should be a power of 2
# $log will be an integer if a power of 2
my $log = log($bufsz) / log(2);
unless ( $log =~ /^[[:digit:]]+$/ ) {
	warn "bufsz of $bufsz is not a power of 2\n";
}

# bufsz should be LT 8M
if ($bufsz > (8 * 2**20) ) {
	die "bufszs of $bufsz is GT 8M (8388608)\n";
}

my $proto = getprotobyname('tcp');    #get the tcp protocol
 
my $sock = IO::Socket::INET->new(
	LocalHost => $localHost,
	LocalPort => $port, 
	Proto => $proto, 
	Listen  => 1, 
	Reuse => 1
) or die "Cannot create socket: $@";

if ($tcpKeepAlive) {
	print "Setting KeepAlive options\n";
	$sock->setsockopt(SOL_SOCKET, SO_KEEPALIVE, $tcpKeepAlive) or die "setsockopt: $!";

	$sock->setsockopt(IPPROTO_TCP, TCP_KEEPIDLE, $tcpIdle) or die "setsockopt: $!" if $tcpIdle;
	$sock->setsockopt(IPPROTO_TCP, TCP_KEEPCNT, $tcpCount) or die "setsockopt: $!" if $tcpCount;
	$sock->setsockopt(IPPROTO_TCP, TCP_KEEPINTVL, $tcpInterval) or die "setsockopt: $!" if $tcpInterval;
}

# default is 0
$sock->setsockopt(IPPROTO_TCP, TCP_USER_TIMEOUT, $tcpUserTimeout) or die "setsockopt: $!";

print "TCP KeepAlive settings\n";

print "keepalive: " . $sock->getsockopt(SOL_SOCKET, SO_KEEPALIVE) . "\n";

# specifying 'Socket::' for old perls where these values are not exported
# see the BEGIN section at the top
print "   keepidle: " . $sock->getsockopt(IPPROTO_TCP, Socket::TCP_KEEPIDLE) . "\n";
print "    keepcnt: " . $sock->getsockopt(IPPROTO_TCP, Socket::TCP_KEEPCNT) . "\n";
print "  keepintvl: " . $sock->getsockopt(IPPROTO_TCP, Socket::TCP_KEEPINTVL) . "\n";
print "TCP Timeout: " . $sock->getsockopt(IPPROTO_TCP, Socket::TCP_USER_TIMEOUT) . "\n";

$bufsz =  $sock->getsockopt(SOL_SOCKET, SO_RCVBUF);

print "KeepAlive is ", $sock->getsockopt(SOL_SOCKET, SO_KEEPALIVE), "\n";
print "Server is now listening ...\n";
print "Initial Buffer size set to: $bufsz\n";
 
$SIG{INT} = sub { shutdown $sock,2; close($sock); die "\nkilled\n" };

#accept incoming connections and talk to clients
while(1)
{
	my ($packets, $totalBytes, $sockElapsed) = (0,0,0);
	my($client);
	my $addrinfo = accept($client , $sock);
 
	my($clientPort, $iaddr) = sockaddr_in($addrinfo);
	my $name = gethostbyaddr($iaddr, AF_INET);

	if ( defined $name) {
		print "Connection accepted from $name : $clientPort\n";
	} else {
		print "Could not lookup name for port $clientPort\n";
	}

 
	binmode $client, ':bytes';
	binmode $sock, ':bytes';

	$bufsz = $sock->getsockopt(SOL_SOCKET, SO_RCVBUF);

	print "Receive Buffer is $bufsz bytes\n";
	print "KeepAlive is ", $sock->getsockopt(SOL_SOCKET, SO_KEEPALIVE), "\n";

	
	my $line;
	my $startTime = [gettimeofday];
	my $t0=[gettimeofday];
	while(my $r=sysread($client,$line,$bufsz)) {

		print '.';
		chomp $line;
		last if $line eq 'END'

	}
	print "\n";

	shutdown $client,2;
	close $client;

	print "\nSocket closed by client - accepting new connections\n";
}
 
#close the socket
shutdown $sock,2;
close($sock);
exit;

sub usage {

my $exitVal = shift;
use File::Basename;
my $basename = basename($0);
print qq{
$basename

usage:  $basename address port bufsz 

$basename --file <filename> --op-line-len N

  --local-host   Local Hostname or IP
  --port         Port number to connect to - default is 4242
  --buffer-size  Size of TCP buffer - default is 8192
  --keepalive    Enable TCP KeepAlive
  
  The following default to system values if not specified

  --tcp-idle          Seconds before sending TCP KeepAlive probes - defaults to system values
  --tcp-interval      How often in seconds to resend an unacked KeepAlive probe	-
  --tcp-count         How many times to resend a KA probe if previous probe was unacked
  --tcp-user-timeout  Time in milliseconds to allow for peer response (man tcp for more)

  --h|help       Help

example: $basename --keepalive --port 1999 --buffer-size 524288 

};

exit eval { defined($exitVal) ? $exitVal : 0 };

}

=head1 bufsz

Setting buffer size via --buffer-size is somewhat futile

You can set it, but the value used will be determined by the kernel.

=cut


