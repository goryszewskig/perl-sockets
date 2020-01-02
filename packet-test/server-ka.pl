#!/usr/bin/env perl

=head1 server.pl

 Though this code ( and client.pl ) use setsockopt() to set the TCP buffer size,
 there does not seem to be any method that actually works.

 The buffer size reported by getsockopt() remains constant regardless of attempts to change it

=cut

use warnings;
use strict;
use IO::Socket::INET;
use Socket qw(SOL_SOCKET SO_RCVBUF SO_KEEPALIVE IPPROTO_IP IP_TTL);
#use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

my $keepAlive=1;

my $port = 4242;

# now setting bufsz dynamically via message from the client
# so this bit is not really necessary - leaving it here for now though

my $bufsz=$ARGV[0];

$bufsz = 2048 unless $bufsz;

# minimal sanity check for bufsz

unless ( $bufsz =~ /^[[:digit:]]+$/ ) {
	die "bufsz of $bufsz is not an integer\n";
}

# bufsz really should be a power of 2
# $log will be an integer if a power of 2
my $log = log($bufsz) / log(2);
unless ( $log =~ /^[[:digit:]]+$/ ) {

	die "bufsz of $bufsz is not a power of 2\n";
}

# bufsz should be LT 8M
if ($bufsz > (8 * 2**20) ) {
	die "bufszs of $bufsz is GT 8M (8388608)\n";
}

$| = 1; # flush stdout
 
my $proto = getprotobyname('tcp');    #get the tcp protocol
 
my $sock = IO::Socket::INET->new(
	LocalPort => $port, 
	Proto => $proto, 
	Listen  => 1, 
	Reuse => 1
) or die "Cannot create socket: $@";

$sock->setsockopt(SOL_SOCKET, SO_RCVBUF, $bufsz) or die "setsockopt: $!";
$sock->setsockopt(SOL_SOCKET, SO_KEEPALIVE, $keepAlive) or die "setsockopt: $!";

print "Initial Receive Buffer is ", $sock->getsockopt(SOL_SOCKET, SO_RCVBUF), " bytes\n";

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

	$sock->setsockopt(SOL_SOCKET, SO_KEEPALIVE, $keepAlive) or die "setsockopt: $!";

	print "Receive Buffer is ", $sock->getsockopt(SOL_SOCKET, SO_RCVBUF), " bytes\n";
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




