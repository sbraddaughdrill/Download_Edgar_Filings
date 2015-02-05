#!/usr/bin/perl

use strict;
use warnings;
use 5.014;

use vars qw/ $VERSION /;
$VERSION = '1.00';

use English qw(-no_match_vars);

use Readonly;

use Benchmark;
#use Win32::Console;

use Mods;

my $asterisk_string = q{*};
Readonly my $ASTERISKS_COUNT => 120;

#eval "mode con lines=50 cols=200";
#perl -e"system q[mode con cols=100 lines=60];"

eval 'system q[mode con cols=120 lines=60];';

print qq{\n}, $asterisk_string x $ASTERISKS_COUNT, qq{\n};
