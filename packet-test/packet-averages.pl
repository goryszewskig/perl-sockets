#!/usr/bin/env perl

use strict;
use warnings;

my %tot=();

while (<STDIN>) {
	next unless /:/;
	next if /(Initial Buffer|Start Time|End Time|totElapsed)/;
	chomp;

	my($key, $value) = split(/:/);

	$tot{"$key"}->[0]++;
	$tot{"$key"}->[1] += $value;
}

foreach my $key ( sort keys %tot ) {
	my $avg = $tot{$key}->[1] / $tot{$key}->[0];
	printf "key/avg: %23s %17.6f\n", $key, $avg;
}
