#!/usr/bin/perl

use Geo::Names::Russian::Mangle;
use utf8;
binmode(STDOUT, ":utf8");

my $m = Geo::Names::Russian::Mangle->new(status_to_right => 1, expand_status => 1);

foreach my $name ('улица Ленина', 'пр-т Энтузиастов', 'улица Набережная', 'пер.Красных Партизан') {
	print $name.' -> '.$m->mangle($name)."\n";
}
