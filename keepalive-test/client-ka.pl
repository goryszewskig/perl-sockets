#!/usr/bin/env perl
 
=head1 socket client 

 This client is send only, does not read

=cut

use warnings;
use strict;
no strict qw( subs ); # hack for old perl version
use IO::Socket::INET;
use Time::HiRes qw(usleep);
use Getopt::Long;

BEGIN {
	eval {
		require Socket;
		Socket->import( qw(SOL_SOCKET SO_SNDBUF SO_KEEPALIVE IPPROTO_IP IP_TTL TCP_KEEPIDLE TCP_KEEPINTVL TCP_KEEPCNT IPPROTO_TCP) );
	};
	
	# hack for old perl versions where Socket.pm does not export TCP_KEEP* values
	if ($@) {
		
		warn "Old Perl Version - setting TCP_KEEP constants manually\n";

		# values are found in /usr/include/netinet/tcp.h

		use Socket qw(SOL_SOCKET SO_SNDBUF SO_KEEPALIVE IPPROTO_IP IP_TTL IPPROTO_TCP);
		*Socket::TCP_KEEPIDLE = sub { 4 };
		*Socket::TCP_KEEPINTVL = sub { 5 };
		*Socket::TCP_KEEPCNT = sub { 6 };
	}
}

sub usage;

my $port=4242;
my $bufsz=8192;
my ($tcpKeepAlive,$tcpIdle,$tcpInterval,$tcpCount) = (0,0,0,0);
my ($remoteHost,$localHost) = ('','');
my $help=undef;

GetOptions (
	"remote-host=s" => \$remoteHost,
	"port=i" => \$port,
	"local-host=s" => \$localHost,
	"buffer-size=i" => \$bufsz,
	"keepalive!" => \$tcpKeepAlive,
	"tcp-idle=i" => \$tcpIdle,
	"tcp-interval=i" => \$tcpInterval,
	"tcp-count=i" => \$tcpCount,
	"h|help!" => \$help,
) or die usage(1);

die usage unless $remoteHost;
die usage unless $localHost;

if ($help) {
	usage;
	exit;
}

# minimal sanity check for bufsz
# should not be necessary since now using Getopt::Long, but leaving it in
unless ( $bufsz =~ /^[[:digit:]]+$/ ) {
	die "bufsz of $bufsz is not an integer\n";
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

       remote host: $remoteHost
              port: $port
             bufsz: $bufsz

};
 
my $proto = getprotobyname('tcp');    #get the tcp protocol
 
print "bufsz: $bufsz\n";

my $sock = IO::Socket::INET->new(
	LocalHost => $localHost,
	LocalPort => $port, 
	Proto => $proto, 
	Reuse => 1
) or die "Cannot create socket: $@";

# see IO::Socket for setsockopt perl docs
$sock->setsockopt(SOL_SOCKET, SO_SNDBUF, $bufsz) or die "setsockopt: $!";

if ($tcpKeepAlive) {
	$sock->setsockopt(SOL_SOCKET, SO_KEEPALIVE, $tcpKeepAlive) or die "setsockopt: $!";

	# specifying 'Socket::' for old perls where these values are not exported
	# see the BEGIN section at the top
	$sock->setsockopt(IPPROTO_TCP, Socket::TCP_KEEPIDLE, $tcpIdle) or die "setsockopt: $!" if $tcpIdle;
	$sock->setsockopt(IPPROTO_TCP, Socket::TCP_KEEPCNT, $tcpCount) or die "setsockopt: $!" if $tcpCount;
	$sock->setsockopt(IPPROTO_TCP, Socket::TCP_KEEPINTVL, $tcpInterval) or die "setsockopt: $!" if $tcpInterval;
}

 
$SIG{INT} = sub { shutdown $sock,2; close($sock); die "\nkilled\n" };

# connect to remote server
my $iaddr = inet_aton($remoteHost) or die "Unable to resolve hostname : $remoteHost";
my $paddr = sockaddr_in($port, $iaddr);    #socket address structure
 
connect($sock , $paddr) or die "connect failed : $!";
print "Connected to $remoteHost on port $port\n";
binmode $sock, ':bytes';

print " Send Buffer is ", $sock->getsockopt(SOL_SOCKET, SO_SNDBUF), " bytes\n";
print " Client KeepAlive is ", $sock->getsockopt(SOL_SOCKET, SO_KEEPALIVE), "\n";
print "Connected...\n";

# use sysdread to get requested buffer size
# otherwise buffered reads are used, which does not allow the required level of control
# use $datasz for debugging
# cli parameter is milliseconds - usleep uses microseconds

my $bytesWritten =  syswrite($sock, 'test', $bufsz); 

print qq{

Press ENTER to complete

};

my $response = <STDIN>;

$bytesWritten =  syswrite($sock, 'END', $bufsz); 
 
# Does not work as expected - socket is still open - see Reuse in socket creation
$sock->setsockopt(SOL_SOCKET, SO_LINGER, pack('II',1,10)) or die "setsockopt: $!";

shutdown $sock,2;
close($sock) or die "cannot close socket - $@\n";
exit;


sub usage {

my $exitVal = shift;
use File::Basename;
my $basename = basename($0);
print qq{
$basename

usage:  $basename address port bufsz 

$basename --file <filename> --op-line-len N

  --remote-host  The host or IP were server.pl is running
  --port         Port number to connect to - default is 4242
  --local-host   The local hostname or IP address to use for the outgoing connection
  --buffer-size  Size of TCP buffer - default is 8192
  --keepalive    Enable TCP KeepAlive
  
  The following default to system values if not specified

  --tcp-idle     Seconds before sending TCP KeepAlive probes - defaults to system values
  --tcp-interval How often in seconds to resend an unacked KeepAlive probe	-
  --tcp-count    How many times to resend a KA probe if previous probe was unacked

  --h|help       Help

example: $basename --remote-host 192.168.1.42 --localhost 192.168.1.75 --port 1999 --buffer-size 524288 

};

exit eval { defined($exitVal) ? $exitVal : 0 };

}



=head1 bufsz

Setting buffer size via --buffer-size is somewhat futile

You can set it, but the value used will be determined by the kernel.

=cut

