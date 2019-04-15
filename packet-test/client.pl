#!/usr/bin/env perl
 
=head1 socket client 

 This client is send only, does not read

=cut

use warnings;
use strict;
use IO::Socket::INET;
use Time::HiRes qw(usleep);
use Socket qw(SOL_SOCKET SO_SNDBUF  IPPROTO_IP IP_TTL);

#foreach my $arg ( @ARGV ) {
#print "arg: $arg\n"
#}

unless ( $ARGV[2] ) {
	print qq {

usage:  client.pl address port bufsz latency

latency is optional (specified in milliseconds )

example: ./client.pl 192.168.1.42 1999 524288 24

};

exit 1;

}

my $dataFile='testdata-100M.dat';

my $remote=$ARGV[0];
my $port = $ARGV[1];
my $bufsz=$ARGV[2];

# specify as milliseconds
my $inducedLatency= $ARGV[3] ? $ARGV[3] : 0;

# minimal sanity check for bufsz
#
unless ( $bufsz =~ /^[[:digit:]]+$/ ) {
	die "bufsz of $bufsz is not an integer\n";
}

unless ( $inducedLatency =~ /^[[:digit:]]+$/ ) {
	die "Latency of inducedLatencybufsz is not an integer\n";
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

print qq{

       remote host: $remote
              port: $port
             bufsz: $bufsz
 simulated latency: $inducedLatency

};
 
my $proto = getprotobyname('tcp');    #get the tcp protocol
 
print "bufsz: $bufsz\n";

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

# cli parameter is milliseconds - usleep uses microseconds
my $microSleep = $inducedLatency * 1000;

print "Simulating Latency at " , $inducedLatency , " milliseconds (", $microSleep , " microseconds)\n" if $microSleep;

while ( my $datasz = sysread($fh,my $data,$bufsz) ) {
	last unless $datasz > 0;
	#print "Data Sz: $datasz\n";
	# syswrite returns bytes written - normally we do not care about this value
	my $bytesWritten =  syswrite($sock, $data, $bufsz); 
	#print "Bytes written: $bytesWritten\n";
	
	usleep $microSleep if $microSleep;
	
}
 
# Does not work as expected - socket is still open - see Reuse in socket creation
$sock->setsockopt(SOL_SOCKET, SO_LINGER, pack('II',1,10)) or die "setsockopt: $!";

shutdown $sock,2;
close($sock) or die "cannot close socket - $@\n";
exit;


