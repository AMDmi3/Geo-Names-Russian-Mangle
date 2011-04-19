#!/usr/bin/perl

use strict;
use warnings;
use Geo::Names::Russian::Mangle;

use utf8;

binmode(STDOUT, ":utf8");

my @testcases = (
	'Ул Ленина',
	'ул Ленина',
	'ул. Ленина',
	'ул.Ленина',
	'улица Ленина',
	'Ленина улица',
	'Ленина ул',
	'Ленина ул.',
	'Ленина, ул',
	'Ленина, ул.',
	'Ленина,ул',
	'Ленина,ул.',
	'Ленина, УЛИЦА',
	'УЛИЦА Ленина',
);

my @modes = (
	{ expand_status => 1, status_to_left => 1, expected => 'улица Ленина' },
	{ expand_status => 1, status_to_right => 1, expected => 'Ленина улица' },
	{ shrink_status => 1, status_to_left => 1, expected => 'ул. Ленина' },
	{ shrink_status => 1, status_to_right => 1, expected => 'Ленина ул.' },
);

my $errors = 0;

foreach my $mode (@modes) {
	print '===> Mode: '.join(', ', keys %$mode)."\n";

	my $mangle = Geo::Names::Russian::Mangle->new(%$mode);

	foreach my $case (@testcases) {
		my $mangled = $mangle->mangle($case);
		print "   $case -> $mangled\n";

		if ($mangled ne $mode->{expected}) {
			$errors++;
			print STDERR "Test failed!\n";
		}
	}
}

if ($errors) {
	print STDERR "Some tests failed!\n";
}

exit $errors;
