#!/usr/bin/env perl
 
=head1 socket client 

 This client is send only, does not read

=cut

use warnings;
use strict;
use IO::Socket::INET;
use Socket qw(SOL_SOCKET SO_SNDBUF  IPPROTO_IP IP_TTL);

my $remote = '192.168.1.56';
$remote = '162.243.157.128';
my $port = 4242;

my $dataFile='testdata-10M.dat';
#$dataFile='/mnt/zips/moriarty/tmp/big-test-file/testdata-1G.dat';

my $bufsz=$ARGV[0];

$bufsz = 2048 unless $bufsz;

# minimal sanity check for bufsz
#
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
 
my $proto = getprotobyname('tcp');    #get the tcp protocol
 
# 1. create a socket handle (descriptor)
#my($sock);
#socket($sock, AF_INET, SOCK_STREAM, $proto) or die $!;

my $sock = IO::Socket::INET->new(LocalPort => $port, Proto => $proto, Reuse => 1)
         or die "Cannot create socket: $@";

$sock->setsockopt(SOL_SOCKET, SO_SNDBUF, $bufsz) or
   die "setsockopt: $!";

print " Send Buffer is ", $sock->getsockopt(SOL_SOCKET, SO_SNDBUF),
	   " bytes\n";
 
# 2. connect to remote server
my $iaddr = inet_aton($remote) or die "Unable to resolve hostname : $remote";
my $paddr = sockaddr_in($port, $iaddr);    #socket address structure
 
connect($sock , $paddr) or die "connect failed : $!";
print "Connected to $remote on port $port\n";
 
# 3. Send some data to remote server - the HTTP get command

open my $fh, '<', $dataFile or die "cannot open $dataFile - $!";

send($sock , "$bufsz\n" , 0);

while (<$fh>) {
	send($sock , $_ , 0);
}
 
# Does not work as expected - socket is still open - see Reuse in socket creation
$sock->setsockopt(SOL_SOCKET, SO_LINGER, pack('II',1,10)) or
	die "setsockopt: $!";

close($sock) or die "cannot close socket - $@\n";
exit(0); 


