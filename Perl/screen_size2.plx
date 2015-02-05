#!/usr/bin/perl

use strict;
use warnings;
use 5.014;

use vars qw/ $VERSION /;
$VERSION = '1.00';

use English qw(-no_match_vars);

use Readonly;

use Benchmark;
use Win32::Console;

use Mods;

my $asterisk_string = q{*};
Readonly my $ASTERISKS_COUNT => 120;

my $console_width = 120;
my $console_height = 25;

my $CONSOLE = Win32::Console->new();
$CONSOLE->Size($console_width, $console_height); # force a console size
my ($actual_width, $actual_height) = $CONSOLE->Size();


print "Console size is $actual_width x $actual_height\n";
print qq{\n}, $asterisk_string x $ASTERISKS_COUNT, qq{\n};
