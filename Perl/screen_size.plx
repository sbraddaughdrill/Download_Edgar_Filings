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

my $OUT = Win32::Console->new(STD_OUTPUT_HANDLE);
my $IN  = Win32::Console->new(STD_INPUT_HANDLE);
$IN->Mode(ENABLE_MOUSE_INPUT|ENABLE_WINDOW_INPUT);

$OUT->Size(180, 200);
my ($maxx, $maxy) = $OUT->MaxWindow;

$OUT->Cls;
$OUT->Cursor(-1, -1, -1, 0);

$OUT->FillAttr($BG_YELLOW|$FG_BLUE, $maxy * $maxx, 0, 0);
$OUT->FillChar('X', $maxy*$maxx, 0, 0);

$OUT->Window(1, 0, 0, $maxx, $maxy);

while ($maxx>1 and $maxy>1) {
    $maxx -= 5;
    $maxy -= 5;
    $OUT->Window(1, 0, 0, $maxx, $maxy);
    sleep 1;
}



$OUT->Window(1, 0, 80, 50);
$OUT->Cls;

print 'Hello\n';