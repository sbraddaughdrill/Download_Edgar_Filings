#!/usr/bin/perl

# $Id: Daughdrill_read_filings_Section_Number.plx;
# $Revision: 1 $
# $HeadURL: 1 $
# $Source: /Perl/Daughdrill_read_filings_Section_Number.plx $
# $Date: 10.30.2012 $
# $Author: S. Brad Daughdrill $

#=====================================================================;
#SCRIPT DETAILS;
#=====================================================================;
# Purpose:       This program is going to obtain certain text from EDGAR filings.  You can extract whatever text you are
#                interested in by changing the regular expressions for the start and end strings below.
# Prerequisites: 1.) Download (http://www.activestate.com/activeperl/downloads) and install Perl to C:\usr
#                2.) Make sure all packages are up-to-date (in command prompt, type "ppm")
#                3.) Associate *.pl files with Perl
#                     - Start Command Prompt (Start >> Programs >> Accessories >> Right-click on Command Prompt >> Run as administrator)
#                     - Type "assoc .pl=PerlScript"
#                4.) Add .PL to your PATHEXT environment variable.
#                     - Start Command Prompt (Start >> Programs >> Accessories >> Right-click on Command Prompt >> Run as administrator)
#                     - Type "SETX PATHEXT %PATHEXT%;.PL"
#                5.) Execute Daughdrill_get_index_files.plx
#                6.) Execute Daughdrill_Download_Filings.plx
# Useage:        1.) Type 'cd ' and then the value of codedirect below
#                2.) Type 'perl ' and then the name of the file
#=====================================================================;
#Pragmata
use 5.014;    #this enables strict
use warnings;

use vars qw/ $VERSION /;
$VERSION = '1.00';

#use re 'debug';
#use diagnostics;

#Modules
use English qw(-no_match_vars);
use Readonly;
use Benchmark;
use Mods;
use List::MoreUtils qw(uniq pairwise);
#Error messages
my $close_err  = "Cannot close:\t";
my $create_err = "Cannot create folder:\t";
my $open_err   = "Cannot open:\t";
my $print_err  = "Cannot print:\t";
my $eval_err   = "Cannot evaluate:\t";




#my @arr1 = ( 1, 0, 0, 0, 1 );#my @arr2 = ( 1, 1, 0, 1, 1 );
my @arr1 = ("Hello","Goodbye");
my @arr2 = ("World","World");

my @sum=();#@sum = pairwise { $a + $b } @arr1, @arr2;

@sum = pairwise { q{Start } . our $a . q{ } . our $b . q{ End}} @arr1, @arr2;

        
        while ( my ( $index, $elem ) = each @sum ) {
            say q{$sum} . q{[} . $index . qq{]:\n} . $elem . qq{\n}
              or croak( $print_err . $ERRNO );
        }