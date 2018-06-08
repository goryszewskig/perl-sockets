#!/usr/bin/env perl
 
=head1 socket client 

 This client is send only, does not read

=cut

use warnings;
use strict;
use IO::Socket::INET;
use Socket qw(SOL_SOCKET SO_SNDBUF  IPPROTO_IP IP_TTL);

my $remote = '192.168.1.56';
my $port = 4242;

my $dataFile='testdata-100M.dat';
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
 
my $sock = IO::Socket::INET->new(LocalPort => $port, Proto => $proto, Reuse => 1)
         or die "Cannot create socket: $@";

$sock->setsockopt(SOL_SOCKET, SO_SNDBUF, $bufsz) or
   die "setsockopt: $!";

print " Send Buffer is ", $sock->getsockopt(SOL_SOCKET, SO_SNDBUF),
	   " bytes\n";
 
$SIG{INT} = sub { shutdown $sock,2; close($sock); die "\nkilled\n" };

# connect to remote server
my $iaddr = inet_aton($remote) or die "Unable to resolve hostname : $remote";
my $paddr = sockaddr_in($port, $iaddr);    #socket address structure
 
connect($sock , $paddr) or die "connect failed : $!";
print "Connected to $remote on port $port\n";
 
open my $fh, '<', $dataFile or die "cannot open $dataFile - $!";
binmode $fh, ':bytes';

send($sock , "$bufsz\n" , 0);
binmode $sock, ':bytes';

# use sysdread to get requested buffer size
# otherwise buffered reads are used, which does not allow the required level of control
# use $datasz for debugging
print "Sending data...\n";

while ( my $datasz = sysread($fh,my $data,$bufsz) ) {
	last unless $datasz > 0;
	#print "Data Sz: $datasz\n";
	# syswrite returns bytes written - normally we do not care about this value
	my $bytesWritten =  syswrite($sock, $data, $bufsz); 
	#print "Bytes written: $bytesWritten\n";
}
 
# Does not work as expected - socket is still open - see Reuse in socket creation
$sock->setsockopt(SOL_SOCKET, SO_LINGER, pack('II',1,10)) or die "setsockopt: $!";

shutdown $sock,2;
close($sock) or die "cannot close socket - $@\n";
exit;


