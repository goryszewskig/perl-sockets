#!/usr/bin/env perl

use warnings;
use strict;
use FileHandle;
use DBI;
use Getopt::Long;
use Data::Dumper;

my %optctl = ();

my($db, $username, $password, $connectionMode);
my$adjustCols=0;
my $help=0;
my $sysdba=0;

Getopt::Long::GetOptions(
	\%optctl,
	"database=s" => \$db,
	"username=s" => \$username,
	"password=s" => \$password,
	"z|h|help!" => \$help
);


usage(0) if $help;

$|=1; # flush output immediately

sub getOraVersion($$$);

my $dbh = DBI->connect(
	'dbi:Oracle:' . $db,
	$username, $password,
	{
		RaiseError => 1,
		AutoCommit => 0,
		ora_session_mode => $connectionMode
	}
);

die "Connect to  $db failed \n" unless $dbh;

my $sql=q{select s.sid, p.spid
from v$session s, v$process p
where s.sid = sys_context('userenv','sid')
	and p.addr = s.paddr};

my $sth=$dbh->prepare($sql);
$sth->execute;

my ($sid, $spid) = $sth->fetchrow_array;
$sth->finish;

print qq{

 SID: $sid
SPID: $spid

};


print "\nPress ENTER to continue\n";

my $response=<STDIN>;

$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	$exitVal = 0 unless defined $exitVal;
	use File::Basename;
	my $basename = basename($0);
	print qq/

usage: $basename

  -database      target instance
  -username      target instance account name
  -password      target instance account password

  example:

  $basename -database dv07 -username scott -password tiger -sysdba  

/;
   exit $exitVal;
};


