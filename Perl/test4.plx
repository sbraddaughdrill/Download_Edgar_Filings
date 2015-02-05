#!/usr/bin/perl

# $Id: Daughdrill_read_filings_Section_Number.plx;
# $Revision: 1 $
# $HeadURL: 1 $
# $Source: /Perl/Daughdrill_read_filings_Section_Number.plx $
# $Date: 10.30.2012 $
# $Author: S. Brad Daughdrill $

use strict;
use warnings;
use 5.014;

use vars qw/ $VERSION /;
$VERSION = '1.00';

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

use English qw(-no_match_vars);

use Readonly;

use Benchmark;
use YAPE::Regex::Explain;
use Mods;
print "YAPE::Regex::Explain->new(qr/['-])->explain";