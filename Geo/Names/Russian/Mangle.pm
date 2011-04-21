package Geo::Names::Russian::Mangle;

use 5.006;
use strict;
use utf8;

our $VERSION = "0.1";

#
# Note: comments in this file are in Russian
#

our $status_parts = [
	# 1 = приоритет
	# 2 = полная форма
	# 3 = каноническая сокращённая форма (undef если нету)
	# 4 = все возможные сокращения

	#   1  2             3         4
	[ 100, 'улица',      'ул.',    qw(ул)                  ],

	[  10, 'площадь',    'пл.',    qw(пл)                  ],
	[  10, 'проезд',     'пр.',    qw(пр пр-д)             ],
	[  10, 'переулок',   'пер.',   qw(пер пер-к)           ],

	[   1, 'аллея',      undef,                            ],
	[   1, 'бульвар',    'бул.',   qw(бул б-р)             ],
	[   1, 'линия',      undef,    qw(лин)                 ],
	[   1, 'метромост',  undef,                            ],
	[   1, 'мост',       undef,                            ],
	[   1, 'набережная', 'наб.',   qw(наб)                 ],
	[   1, 'подъезд',    undef,                            ],
	[   1, 'просек',     undef,    qw(пр)                  ],
	[   1, 'просека',    undef,                            ],
	[   1, 'проспект',   'пр-т',   qw(пр просп пр-кт пр-т) ],
	[   1, 'путепровод', undef,                            ],
	[   1, 'тоннель',    undef,                            ],
	[   1, 'тракт',      undef,    qw(тр-т тр)             ],
	[   1, 'тропа',      undef,                            ],
	[   1, 'туннель',    undef,                            ],
	[   1, 'тупик',      'туп.',   qw(туп)                 ],
	[   1, 'шоссе',      'ш.',     qw(ш)                   ],
	[   1, 'эстакада',   undef,    qw(эст)                 ],
	[   1, 'дорога',     'дор.',   qw(дор)                 ],
	[   1, 'спуск',      undef,                            ],
	[   1, 'подход',     undef,                            ],
	[   1, 'съезд',      undef,                            ],
	[   1, 'заезд',      undef,                            ],
];

sub new {
	my ($class, %args) = @_;

	my $self = bless {
		%args,
	}, $class;

	foreach my $status (@$status_parts) {
		foreach my $variant (grep /\S/, @$status[1, 3 .. $#$status]) {
			$self->{status}->{lc($variant)} = $status;
		}
	}

	return $self;
}

sub mangle {
	my ($this, $name) = @_;

	my @parts = ($name =~ /(\s+|[.,]+|[^\s.,]+)/g);

	# Найти статусную часть с наибольшим приоритетом
	my ($pos, $status);
	for (my $i = 0; $i <= $#parts; $i++) {
		my $part = lc($parts[$i]);
		if (defined $this->{status}->{$part} && (!defined($status) || $this->{status}->{$part}->[0] > $status->[0])) {
			$status = $this->{status}->{$part};
			$pos = $i;
		}
	}

	if (!defined $status) {
		if ($this->{noerror}) {
			return $name;
		} else {
			die "Cannot determine status part";
		}
	}

	# Вменяемо вырезять статусную часть
	# Умеем: "ул Ленина", "ул. Ленина", "ул.Ленина", "Ленина,ул", "Ленина, ул"
	if ($pos + 1 <= $#parts && $parts[$pos + 1] eq '.') {
		$parts[$pos] .= splice @parts, $pos + 1, 1;
	}
	if ($pos + 1 <= $#parts && $parts[$pos + 1] !~ /\s/) {
		splice @parts, $pos + 1, 0, ' ';
	}
	if ($pos - 2 >= 0 && $parts[$pos - 2] eq ',' && $parts[$pos-1] =~ /\s/) {
		splice @parts, $pos - 2, 1;
		$pos--;
	}
	if ($pos - 1 >= 0 && $parts[$pos - 1] eq ',') {
		$parts[$pos-1] = ' ';
	}

	# Выбрать заказанный вариант написания
	if (defined $this->{expand_status}) {
		$parts[$pos] = $status->[1];
	}
	if (defined $this->{shrink_status}) {
		$parts[$pos] = $status->[2] if (defined $status->[2]);
	}
	if (defined $this->{lowercase_status}) {
		$parts[$pos] = lc($parts[$pos]);
	}

	# Поставить с нужной стороны
	if (defined $this->{status_to_left} && $pos != 0) {
		my ($space, $status) = splice @parts, $pos-1, 2;
		unshift @parts, $status, ' ';
		$pos = 0;
	}
	if (defined $this->{status_to_right} && $pos != $#parts) {
		my ($status, $space) = splice @parts, $pos, 2;
		push @parts, ' ', $status;
		$pos = $#parts;
	}

	# Нормализация пробелов
	my $joined = join('', @parts);
	if ($this->{normalize_whitespace}) {
		$joined =~ s/^\s+//;
		$joined =~ s/\s+$//;
		$joined =~ s/\s{2,}/ /;
	}

	return $joined;
}

1;
__END__

=encoding utf8

=head1 NAME

Geo::Names::Russian::Mangle - transform Russian street names

=head1 SYNOPSIS

 my $mangler = Geo::Names::Russian::Mangle->new(expand_status => 1, status_to_left => 1)

 print $mangler->mangle('улица Ленина');    # outputs "улица Ленина"
 print $mangler->mangle('Ленина ул.');      # outputs "улица Ленина"
 print $mangler->mangle('ул.Ленина');       # outputs "улица Ленина"
 print $mangler->mangle('Ленина, улица');   # outputs "улица Ленина"

=head1 DESCRIPTION

This module provides a way to transform Russian street names between
different variangts of writing. It can determine status part in the
name and convert it to full or abbreviated variant and to to move
it to the beginning or to the end of a toponym.

The best use for module is to canonicalize list of street names and
to prepare it for various uses, such as placing on map (abbreviations
preferred) ot to displaying in lists (status part should be moved
to the end).

This module tries its best to preserve non-status part of the name,
including whitespace (althrough it may reduce extra spaces as well).

=head1 CONSTRUCTOR METHODS

The following constructor method is available:

=over

=item $m = Geo::Names::Russian::Mangle->new( %options )

This method constructs a new C<Geo::Names::Russian::Mangle> object
and returns it. Key/value pair arguments may be provided to specify
which conversions are requested and control behaviour of those. The
following options are available:

=over

=item expand_status

Expands status word to full variant (eg. 'ул.' -> 'улица')

=item shrink_status

Shrinks status word to abbreviated variant (eg. 'улица' -> 'ул.').
Note that not all status words have abbreviated variant (for example,
'аллея' doesn't), and such words are left unmodified. You may use
both C<expand_status> and C<shrink_status> to shrink status if there
is abbreviation for and and to expand it otherwise.

lowercase_status

Makes status part lowercase. May be useful if you use neither of
C<expand_status> and C<shrink_status>.

=item status_to_left

Moves status part to the left.

=item status_to_right

Moves status part to the right.

=item normalize_whitespace

Turns multiple consequential whitespace characters into a single
space. Also trims whirespace from the left and from the right of
a toponym.

=item noerror

Instead of dying when status part cannot be determined, just return
unmodified input.

=back

=back

=head1 METHODS

=over

=item $m->mangle( $string )

Transforms string according to rules specified in constructor,
returns transformed string.

=back

=head1 AUTHOR

Dmitry Marakasov E<lt>amdmi3@amdmi3.ruE<gt>

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry Marakasov

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
