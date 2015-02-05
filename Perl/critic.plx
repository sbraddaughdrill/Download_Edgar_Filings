#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;

#my $file = "thing.plx";
my $file = "Daughdrill_read_filings_Section_Number.plx";
my $critic = Perl::Critic->new(-severity=>1);
my @violations = $critic->critique($file);
print "@violations\n";