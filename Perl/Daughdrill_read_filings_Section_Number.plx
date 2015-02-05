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

#use Mods;
#use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
#use Carp qw( croak );
#use Fcntl;
#use HTML::Formatter;      #get the HTML-Format package from the package manager.
#use HTML::TreeBuilder;    #get the HTML-TREE from the package manager
#use HTML::FormatText;
#use Net::FTP;
#use Tie::File;

use List::MoreUtils qw(apply pairwise uniq);
use PadWalker qw();

#=====================================================================;
#INITIAL SETUP;
#=====================================================================;
my $source_dir =
  'C:\\Users\\S. Brad Daughdrill\\Dropbox\\Research\\3rd-Year_Paper\\Perl'
  ;    # Home;

#my $source_dir='C:\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl';                                              # Office;
#my $source_dir='\\tsclient\\C\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl';                                   # CoralSea from Office;
#my $source_dir='\\tsclient\\C\\Users\\S. Brad Daughdrill\\Documents\\My Dropbox\\Research\\3rd-Year_Paper\\Perl';           # CoralSea from Home;

#my $output_dir = 'C:\\Perl_Test';    # Home;

my $output_dir = 'H:\\Research\\Mutual_Funds\\Data\\Perl';    # Office;

#Common strings
my $empty_str    = q{};
my $blank_str    = q{ };
my $asterisk_str = q{*};

#Error messages
my $close_err  = "Cannot close:\t";
my $create_err = "Cannot create folder:\t";
my $open_err   = "Cannot open:\t";
my $print_err  = "Cannot print:\t";

#Value for map functions
#Readonly my $MAP_ELEM => -1;

#Set the console size of a running console
Readonly my $CONSOLE_WIDTH => 170;

#Readonly my $CONSOLE_HEIGHT => 999;
Readonly my $CONSOLE_HEIGHT => 9999;
eval { system "mode con cols=$CONSOLE_WIDTH lines=$CONSOLE_HEIGHT"; 1; } or do {
    if ($EVAL_ERROR) {
        error( "Cannot evaluate:\t" . $EVAL_ERROR );
    }
};

#=====================================================================;
#VARIABLES TO CHANGE;
#=====================================================================;

#Folder year (1999-2008)
Readonly my $YEAR => 2008;

#Set to 1 if want to output to file or 0 to screen
Readonly my $OUTPUT_TO_FILE => 1;

#Set the value for irrelevant numbers
Readonly my $TRASH_VALUE => -999;

#Set the max value for section numbers in TOC
Readonly my $TOC_CUTOFF => 30;

#The parent directory of the downloaded filings
my $dl_folder = $empty_str;
#$dl_folder .= 'N-1A';
#$dl_folder .= 'N-1A';
$dl_folder .= 'Filings';

#The sub directory of the downloaded filings
my $org_folder = $empty_str;
$org_folder .= 'original_trim';

#The directory of the extracted filings
my $extract_folder = $empty_str;
$extract_folder .= 'extract';

#If using windows, set to '\\' - if mac (or unix), set to '/';
my $sep = $empty_str;
$sep .= q{\\};

#=====================================================================;
#STRINGS FOR REGEX;
#=====================================================================;
my $accnum_str = 'Accession Number:';
my $date_str   = 'Filed as of Date:';
my $name_str   = 'Company Conformed Name:';
my $cik_str    = 'Central Index Key:';
my $sic_str    = 'Standard Industrial Classification:';
my $sec_str    = 'Investment Objective';

#=====================================================================;
#UPCASE STRINGS;
#=====================================================================;
my $accnum_str_u = uc $accnum_str;
my $date_str_u   = uc $date_str;
my $name_str_u   = uc $name_str;
my $cik_str_u    = uc $cik_str;
my $sic_str_u    = uc $sic_str;
my $sec_str_u    = uc $sec_str;

#=====================================================================;
#REPLACE SPACES IN STRINGS WITH [\s]
#=====================================================================;

my $replace_space_pat = q{[ ]};
my $replace_space_rx  = qr{$replace_space_pat}xms;
my $replace_space_sub = q{[\\s]};

my $accnum_pat =
  $accnum_str_u =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $date_pat  = $date_str_u =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $name_pat  = $name_str_u =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $cik_pat   = $cik_str_u  =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $sic_pat   = $sic_str_u  =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $sec_pat_1 = $sec_str    =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $sec_pat_2 = $sec_str_u  =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;

$accnum_pat = trim($accnum_pat);
$date_pat   = trim($date_pat);
$name_pat   = trim($name_pat);
$cik_pat    = trim($cik_pat);
$sic_pat    = trim($sic_pat);
$sec_pat_1  = trim($sec_pat_1);
$sec_pat_2  = trim($sec_pat_2);

#=====================================================================;
#CREATE REGEX PATTERNS AND COMPILE THEM;
#=====================================================================;

#REGEX for portfolios
my $portfolios_pat = $empty_str;
$portfolios_pat .= 'portfolios';
my $portfolios_rx = qr{$portfolios_pat}xms;

#REGEX for files
my $file_pat = $empty_str;
$file_pat .= '^[.]';
my $file_rx = qr{$file_pat}xms;

#REGEX for html
my $html_pat = $empty_str;
$html_pat .= '<HTML>';
my $html_rx = qr{$html_pat}xms;

#REGEX for accession number
my $accnum_comb_pat = $empty_str;
$accnum_comb_pat .= q{(} . q{?<=(} . $accnum_pat . q{)} . q{)};
$accnum_comb_pat .= '[\s]*?';
$accnum_comb_pat .= '(\d+)';
my $accnum_rx = qr{$accnum_comb_pat}xms;

#REGEX for filing date
my $date_comb_pat = $empty_str;
$date_comb_pat .= q{(} . q{?<=(} . $date_pat . q{)} . q{)};
$date_comb_pat .= '[\s]*?';
$date_comb_pat .= '(\d+)';
my $date_rx = qr{$date_comb_pat}xms;

#REGEX for fund name
my $name_comb_pat = $empty_str;
$name_comb_pat .= q{(} . q{?<=(} . $name_pat . q{)} . q{)};
$name_comb_pat .= '.*?';
$name_comb_pat .= '((^\s*?)(?=CENTRAL))';
my $name_rx = qr{$name_comb_pat}xms;

#REGEX for CIK
my $cik_comb_pat = $empty_str;
$cik_comb_pat .= q{(} . q{?<=(} . $cik_pat . q{)} . q{)};
$cik_comb_pat .= '[\s]*?';
$cik_comb_pat .= '(\d+)';
my $cik_rx = qr{$cik_comb_pat}xms;

#REGEX for SIC
my $sic_comb_pat = $empty_str;
$sic_comb_pat .= q{(} . q{?<=(} . $sic_pat . q{)} . q{)};
$sic_comb_pat .= '[\s]*?';
$sic_comb_pat .= '(\d+)';
my $sic_rx = qr{$sic_comb_pat}xms;

#REGEX for temporary section number
my $sec_num_temp_comb_pat = $empty_str;
$sec_num_temp_comb_pat .= '((?:(\S+\s+){1,10})' . $sec_pat_1 . q{)};

#$sec_num_temp_comb_pat .= '((?:(\S+\s+){1,10})' . $sec_pat_2 . q{)};
my $sec_num_temp_rx = qr{$sec_num_temp_comb_pat}xms;

#REGEX for section number
my $sec_num_comb_pat = $empty_str;
$sec_num_comb_pat .= '(\d+)(?!\D*\d)';
my $sec_num_rx = qr{$sec_num_comb_pat}xms;

#Specify the start of the text you are looking for.
#my $sec_pat = $empty_str;
#$sec_pat .= $sec_pat_1;
#$sec_pat .= 'Investment[\s]Objective';
#$sec_pat .= 'INVESTMENT[\s]OBJECTIVE';
#$sec_pat .= 'Investment[\s]Objective[\s]And[\s]Policies';
#$sec_pat .= 'Item 9';    #NOTE a strange case I</a>tem 9;
#$sec_pat .= '((^\s*?)Item\s+[89]A[\.\-]?\s+Controls[^\d]*?procedure[^\d]*?\n)';

#Specify the start of the text you are looking for. You my need a different one for HTML versus text filings
my $start_pat_htm = $empty_str;
$start_pat_htm .=
'((>\s?|^\s*?)Item(&.{1,5};\s*)*\s*[89]A\.?\s*(<[^<]*>\s*)*(&.{1,5};\s*)*\.?(<[^<]*>\s*)*\s*Control[^\d]*?Procedure[^\d]*?(\n|<))';

#Specify keywords/phrases you expect to find within the item (make sure the words phrases are not also in the start or end string)
my $keywords = $empty_str;
$keywords .=
'(none|not\s*applicable|no\s*change|January|February|March|April|May|June|July|August|September|October|November|December)';

#=====================================================================;
#BEGIN SCRIPT;
#=====================================================================;
print "Begin Script\n" or croak( $print_err . $ERRNO );

#Start timer
my $start_run = Benchmark->new;

#Variables for each iteration
my $data             = $empty_str;
my $data_temp        = $empty_str;
my $portfolios_data  = $empty_str;
my $portfolios_count = 0;
my $portfolios_flag  = 0;
my $html             = 0;
my $acc_num          = $empty_str;
my $file_date        = $empty_str;
my $cik              = $empty_str;
my $sic              = $empty_str;
my $name             = $empty_str;
my $audit_opinion    = $empty_str;
my $ao               = $empty_str;
my $tree             = $empty_str;

#my $outfiler="";
my @finds      = ();
my $finds_size = 0;
my $prev_lines = 0;
my $tag_lines  = 0;
my $line       = 0;
my $formatter  = $empty_str;

my $sec_temp               = $empty_str;
my @sec_temps              = ();
my @sec_temps_nums         = ();
my @sec_temps_u            = ();
my @sec_temps_no_na        = ();
my $sec_title              = $empty_str;
my @sec_titles             = ();
my $sec_title_replace_dot  = $empty_str;
my @sec_titles_replace_dot = ();
my @sec_titles_no_na       = ();
my @sec_titles_u           = ();

my $sec_num         = $empty_str;
my @sec_nums        = ();
my @sec_nums_u      = ();
my @sec_nums_no_na  = ();
my @sec_nums_no_yr  = ();
my @sec_nums_trim   = ();
my $sec_nums_str    = $empty_str;
my $sec_num_next_1  = 0;
my @sec_nums_next_1 = ();
my $sec_num_next_2  = 0;
my @sec_nums_next_2 = ();

my $sec_num_next_comb_pat            = $empty_str;
my @sec_num_next_comb_pats_1         = ();
my $sec_num_next_comb_pat2           = $empty_str;
my @sec_num_next_comb_pats_2         = ();
my $sec_title_replace_dot_pat        = $empty_str;
my $sec_title_next_replace_dot_pat   = $empty_str;
my $sec_title_next_short_pat         = $empty_str;
my $sec_title_next_replace_space_pat = $empty_str;
my $sec_title_next_replace_space_sub = $empty_str;
my $sec_comb_pat                     = $empty_str;
my @sec_comb_pats                    = ();

my $sec_num_next_comb_rx            = $empty_str;
my @sec_num_next_comb_rxs_1         = ();
my $sec_num_next_comb_rx2           = $empty_str;
my @sec_num_next_comb_rxs_2         = ();
my $sec_title_replace_dot_rx        = $empty_str;
my $sec_title_next_replace_dot_rx   = $empty_str;
my $sec_title_next_short_rx         = $empty_str;
my $sec_title_next_replace_space_rx = $empty_str;
my $sec_comb_rx                     = $empty_str;

my $sec_title_next_temp    = $empty_str;
my @sec_titles_next_temp   = ();
my @sec_titles_next_temp_u = ();
my $sec_title_next         = $empty_str;
my @sec_titles_next        = ();
my @sec_titles_next_no_na  = ();
my @sec_titles_next_u      = ();

my $sec_title_next_replace_dot      = $empty_str;
my @sec_titles_next_replace_dot     = ();
my $sec_title_next_short            = $empty_str;
my @sec_titles_next_short           = ();
my @sec_titles_next_short_no_na     = ();
my @sec_titles_next_short_u         = ();
my $sec_title_next_short_uc         = $empty_str;
my @sec_titles_next_short_uc        = ();
my $sec_title_next_replace_space_1  = $empty_str;
my @sec_titles_next_replace_space_1 = ();
my $sec_title_next_replace_space_2  = $empty_str;
my @sec_titles_next_replace_space_2 = ();
my $sec                             = $empty_str;

#The following two steps open the directory containing the files you plan to read and then stores the name of each file in an array called @new1.
opendir my $dir_open, "$output_dir$sep$dl_folder$sep$YEAR$sep$org_folder"
  or croak( $open_err . $ERRNO );

my @new1 = ();
@new1 = readdir $dir_open;

#while (my ($index, $elem) = each @new1) {say q{$new1[} . $index . qq{]:\n} . $elem . qq{\n} or croak( $print_err . $ERRNO );}

#We will now loop through each file.  The file names have been stored in the array called @new1;
#foreach my $file ( $new1[2] ) {
foreach my $file (@new1) {

   #This prevents me from reading the first two entries in a directory . and ..;
    if ( $file =~ m{$file_rx}xms ) { next; }

    #ReInitialize the variable names.
    $data             = $empty_str;
    $data_temp        = $empty_str;
    $portfolios_data  = $empty_str;
    $portfolios_count = 0;
    $portfolios_flag  = 0;
    $html             = 0;
    $acc_num          = $empty_str;
    $file_date        = $empty_str;
    $cik              = $empty_str;
    $sic              = $empty_str;
    $name             = $empty_str;
    $audit_opinion    = $empty_str;
    $ao               = $empty_str;
    $tree             = $empty_str;

    #$outfiler="";
    @finds      = ();
    $finds_size = 0;
    $prev_lines = 0;
    $tag_lines  = 0;
    $line       = 0;
    $formatter  = $empty_str;

    $sec_temp               = $empty_str;
    @sec_temps              = ();
    @sec_temps_nums         = ();
    @sec_temps_u            = ();
    @sec_temps_no_na        = ();
    $sec_title              = $empty_str;
    @sec_titles             = ();
    $sec_title_replace_dot  = $empty_str;
    @sec_titles_replace_dot = ();
    @sec_titles_no_na       = ();
    @sec_titles_u           = ();

    $sec_num         = $empty_str;
    @sec_nums        = ();
    @sec_nums_u      = ();
    @sec_nums_no_na  = ();
    @sec_nums_no_yr  = ();
    @sec_nums_trim   = ();
    $sec_nums_str    = $empty_str;
    $sec_num_next_1  = 0;
    @sec_nums_next_1 = ();
    $sec_num_next_2  = 0;
    @sec_nums_next_2 = ();

    $sec_num_next_comb_pat            = $empty_str;
    @sec_num_next_comb_pats_1         = ();
    $sec_num_next_comb_pat2           = $empty_str;
    @sec_num_next_comb_pats_2         = ();
    $sec_title_replace_dot_pat        = $empty_str;
    $sec_title_next_replace_dot_pat   = $empty_str;
    $sec_title_next_short_pat         = $empty_str;
    $sec_title_next_replace_space_pat = $empty_str;
    $sec_title_next_replace_space_sub = $empty_str;
    $sec_comb_pat                     = $empty_str;
    @sec_comb_pats                    = ();

    $sec_num_next_comb_rx            = $empty_str;
    @sec_num_next_comb_rxs_1         = ();
    $sec_num_next_comb_rx2           = $empty_str;
    @sec_num_next_comb_rxs_2         = ();
    $sec_title_replace_dot_rx        = $empty_str;
    $sec_title_next_replace_dot_rx   = $empty_str;
    $sec_title_next_short_rx         = $empty_str;
    $sec_title_next_replace_space_rx = $empty_str;
    $sec_comb_rx                     = $empty_str;

    $sec_title_next_temp    = $empty_str;
    @sec_titles_next_temp   = ();
    @sec_titles_next_temp_u = ();
    $sec_title_next         = $empty_str;
    @sec_titles_next        = ();
    @sec_titles_next_no_na  = ();
    @sec_titles_next_u      = ();

    $sec_title_next_replace_dot      = $empty_str;
    @sec_titles_next_replace_dot     = ();
    $sec_title_next_short            = $empty_str;
    @sec_titles_next_short           = ();
    @sec_titles_next_short_no_na     = ();
    @sec_titles_next_short_u         = ();
    $sec_title_next_short_uc         = $empty_str;
    @sec_titles_next_short_uc        = ();
    $sec_title_next_replace_space_1  = $empty_str;
    @sec_titles_next_replace_space_1 = ();
    $sec_title_next_replace_space_2  = $empty_str;
    @sec_titles_next_replace_space_2 = ();
    $sec                             = $empty_str;

    #Open the file and put the file in variable called $data
    #$data will contain the entire filing
    {
#This step removes the default end of line character (\n) so the the entire file can be read in at once and read the contents into data;
        local $INPUT_RECORD_SEPARATOR = undef;
        open my $filehandle_open, '<',
          "$output_dir$sep$dl_folder$sep$YEAR$sep$org_folder$sep" . "$file"
          or croak( $open_err . $ERRNO );
        $data = <$filehandle_open>;
        close $filehandle_open
          or croak( $close_err . $ERRNO );
    }

    #The following counts the time the word 'portfolios' appears in the text.
    #This is used as a proxy for multiple portoflios in a filing.

    $data_temp = $data;
    do {
        if ( $data_temp =~ /$portfolios_pat/i ) {
            $data_temp = $';
            $portfolios_count++;
        }
        else {
            $portfolios_flag = 1;
        }
    } until $portfolios_flag == 1;

#The following steps obtain basic data from the filings
#The $number variables contain the parts of the string that matched the capturing groups in the pattern for your last regex match if the match was successful.
#/i makes the regex match case insensitive.
#/s enables "single-line mode". In this mode, the dot matches newlines.
#/m enables "multi-line mode". In this mode, the caret and dollar match before and after newlines in the subject string.
#/g is a looping modifier

#The first if statement determines whether the filing is in HTML format or plain text.
#if ( $data =~ m{$html_rx}xsmi ) { $html = 1; }
    if ( $data =~ m{($accnum_rx)}xsm ) {
        $acc_num = trim($1);
    }
    if ( $data =~ m{($date_rx)}xsm ) {
        $file_date = trim($1);
    }
    if ( $data =~ m{($cik_rx)}xsm ) {
        $cik = trim($1);
    }
    if ( $data =~ m{($sic_rx)}xsm ) {
        $sic = trim($1);
    }
    if ( $data =~ m{($name_rx)}xsm ) {
        $name = trim($1);

        #print qq{\$1:\n} . $1. qq{\n} or croak( $print_err . $ERRNO );
        #print qq{\$2:\n} . $2. qq{\n} or croak( $print_err . $ERRNO );
        #print qq{\$3:\n} . $3. qq{\n} or croak( $print_err . $ERRNO );
        #print qq{\$&:\n} . $&. qq{\n} or croak( $print_err . $ERRNO );

    }

#The following steps extract the audit opinion (or whatever section of text you want)

    #########################################################################;
    #Find the text with Investment Objective in it;
    #########################################################################;

    @sec_temps = ( $data =~ m{($sec_num_temp_rx)}xsmcgi );

    #print_list_with_err( q{@sec_temps}, q{$print_err} );

    #Empty elements if they do not have numbers
    while ( my ( $index, $elem ) = each @sec_temps ) {
        if ( $elem =~ m/((.*)?\d+(.*)?)/xsmi ) {
            push @sec_temps_nums, $sec_temps[$index];
        }
        else {
            push @sec_temps_nums, $empty_str;
        }
    }

    #print_list_with_err(q{@sec_temps_nums}, q{$print_err} );

    #Remove empty elements
    @sec_temps_no_na = grep { $_ } @sec_temps_nums;

    #print_list_with_err(q{@sec_temps_no_na}, q{$print_err} );

    #Keep only unique elements
    @sec_temps_u = uniq(@sec_temps_no_na);

    #print_list_with_err(q{@sec_temps_u}, q{$print_err} );

    #########################################################################;
    #Find the section number;
    #########################################################################;

    @sec_nums =
      map { /((\d*)(?!.*\d))/xsmgi ? $1 : $empty_str } @sec_temps_u;

    #print_list_with_err(q{@sec_nums}, q{$print_err} );

    #Remove empty elements
    @sec_nums_no_na = grep { $_ } @sec_nums;

    #print_list_with_err(q{@sec_nums_no_na}, q{$print_err} );

    #Keep only unique elements
    @sec_nums_u = uniq(@sec_nums_no_na);

    #print_list_with_err(q{@sec_nums_u}, q{$print_err} );

    #Remove elements larger than 30
    @sec_nums_no_yr = grep { $_ <= $TOC_CUTOFF } @sec_nums_u;

    #print_list_with_err(q{@sec_nums_no_yr}, q{$print_err} );

    #Remove elements that are no longer numerically ascending
    while ( my ( $index, $elem ) = each @sec_nums_no_yr ) {
        my $num_elements = @sec_nums_no_yr;
        my $index_up     = $index + 1;
        my $elem_up      = $sec_nums_no_yr[$index_up];
        if ( $index_up == $num_elements ) {
            $elem_up = $TRASH_VALUE;
        }
        if ( $num_elements == 1 ) {
            push @sec_nums_trim, $sec_nums_no_yr[$index];
        }
        else {
            if ( $index == 0 ) {
                push @sec_nums_trim, $sec_nums_no_yr[$index];
            }
            if ( $elem < $elem_up ) {
                push @sec_nums_trim, $sec_nums_no_yr[$index_up];
            }
        }
    }

    #print_list_with_err( q{@sec_nums_trim}, q{$print_err} );
    $sec_num = $sec_nums_trim[0];

    #$sec_nums_str = join('|', @sec_nums_trim);

    #########################################################################;
    #Find the Section Titles;
    #########################################################################;

    @sec_titles =
      map { /((?<=((\d)(?!.*\d))).*)/xsmgi ? $1 : $empty_str } @sec_temps_u;

    #print_list_with_err(q{@sec_titles}, q{$print_err} );

    #Replace all dots in section title and next section title with spaces;
    @sec_titles_replace_dot = @sec_titles;
    s/[.]/$blank_str/xsmg for @sec_titles_replace_dot;

    #print_list_with_err( q{@sec_titles_replace_dot}, q{$print_err} );

    #Trim strings in array;
    @sec_titles_replace_dot = map { trim($_) } @sec_titles_replace_dot;

    #print_list_with_err( q{@sec_titles_replace_dot}, q{$print_err} );

    #Remove empty elements
    @sec_titles_no_na = grep { $_ } @sec_titles_replace_dot;

    #print_list_with_err( q{@sec_titles_no_na}, q{$print_err} );

    #Keep only unique elements
    @sec_titles_u = uniq(@sec_titles_no_na);
    print_list_with_err( q{@sec_titles_u}, q{$print_err} );

    #########################################################################;
    #Find the next section number  in the TOC;
    #########################################################################;
    @sec_nums_next_1 = map { $_ + 1 } @sec_nums_trim;

    #print_list_with_err(q{@sec_nums_next_1}, q{$print_err} );

    #########################################################################;
    #Find the next, next section number in the TOC;
    #########################################################################;
    @sec_nums_next_2 = map { $_ + 2 } @sec_nums_trim;

    #print_list_with_err(q{@sec_nums_next_2}, q{$print_err} );

    #########################################################################;
    #Find the title of the next section in the TOC;
    #########################################################################;
    @sec_num_next_comb_pats_1 =
      map { q{(?<=(} . $sec_pat_1 . q{)).*?(} . "$_" } @sec_nums_trim;

    @sec_num_next_comb_pats_1 = do {
        pairwise { $a . q{A|} . $b . q{)} } @sec_num_next_comb_pats_1,
          @sec_nums_next_1;
    };

    @sec_num_next_comb_pats_1 =
      map { "$_" . q{.*?} } @sec_num_next_comb_pats_1;

    @sec_num_next_comb_pats_1 = do {
        pairwise { $a . q{(?=} . $b } @sec_num_next_comb_pats_1,
          @sec_nums_next_1;
    };

    @sec_num_next_comb_pats_1 = do {
        pairwise { $a . q{A|} . $b . q{)} } @sec_num_next_comb_pats_1,
          @sec_nums_next_2;
    };

    #print_list_with_err( q{@sec_num_next_comb_pats_1}, q{$print_err} );

    @sec_num_next_comb_rxs_1 = map { qr{$_}xsm } @sec_num_next_comb_pats_1;

    #print_list_with_err( q{@sec_num_next_comb_rxs_1}, q{$print_err} );

    while ( my ( $index, $elem ) = each @sec_num_next_comb_rxs_1 ) {
        if ( $data =~ m{($elem)}xsm ) {
            push @sec_titles_next_temp, $1;
        }
    }

    #print_list_with_err( q{@sec_titles_next_temp}, q{$print_err} );

    #Keep only unique elements
    @sec_titles_next_temp_u = uniq(@sec_titles_next_temp);

    #print_list_with_err( q{@sec_titles_next_temp_u}, q{$print_err} );

    @sec_num_next_comb_pats_2 =
      map { q{(?<=} . "$_" . q{).*} } @sec_nums_next_1;

    #print_list_with_err( q{@sec_num_next_comb_pats_2}, q{$print_err} );

    @sec_num_next_comb_rxs_2 = map { qr{$_}xsm } @sec_num_next_comb_pats_2;

    #print_list_with_err( q{@sec_num_next_comb_rxs_2}, q{$print_err} );

    @sec_titles_next = @sec_titles_next_temp_u;
    while ( my ( $index, $elem ) = each @sec_num_next_comb_pats_2 ) {
        @sec_titles_next = map { /($elem)/xsm ? $1 : $_ } @sec_titles_next;
    }

    #print_list_with_err( q{@sec_titles_next}, q{$print_err} );

    #Replace all dots in section title and next section title with spaces;
    @sec_titles_next_replace_dot = @sec_titles_next;
    s/[.]/$blank_str/xsmg for @sec_titles_next_replace_dot;

    #print_list_with_err( q{@sec_titles_next_replace_dot}, q{$print_err} );

    #Trim strings in array;
    @sec_titles_next_replace_dot =
      map { trim($_) } @sec_titles_next_replace_dot;

    #print_list_with_err( q{@sec_titles_next_replace_dot}, q{$print_err} );

    #Remove empty elements
    @sec_titles_next_no_na = grep { $_ } @sec_titles_next_replace_dot;

    #print_list_with_err( q{@sec_titles_next_no_na}, q{$print_err} );

    #Keep only unique elements
    @sec_titles_next_u = uniq(@sec_titles_next_no_na);

    #print_list_with_err( q{@sec_titles_next_u}, q{$print_err} );

    #########################################################################;
    #Create short title for next section;
    #########################################################################;

    @sec_titles_next_short =
      map { /(^.+?(?=([ ]{3,}|[;]|\n|\t|\r)))/xsm } @sec_titles_next_u;

    #print_list_with_err( q{@sec_titles_next_short}, q{$print_err} );

    #Trim strings in array;
    @sec_titles_next_short =
      map { trim($_) } @sec_titles_next_short;

    #print_list_with_err( q{@sec_titles_next_short}, q{$print_err} );

    #Remove empty elements
    @sec_titles_next_short_no_na = grep { $_ } @sec_titles_next_short;

    #print_list_with_err( q{@sec_titles_next_short_no_na}, q{$print_err} );

    #Keep only unique elements
    @sec_titles_next_short_u = uniq(@sec_titles_next_short_no_na);

    #print_list_with_err( q{@sec_titles_next_short_u}, q{$print_err} );

    #Upcase titles of next section;
    @sec_titles_next_short_uc = map { uc $_ } @sec_titles_next_short_u;

    #print_list_with_err( q{@sec_titles_next_short_uc}, q{$print_err} );

    #########################################################################;
    #Replace spaces in $sec_title_next_short with [\s];
    #########################################################################;

    @sec_titles_next_replace_space_1 = @sec_titles_next_short_u;
    s/[ ]/[\\s]/xsmg for @sec_titles_next_replace_space_1;

    #print_list_with_err( q{@sec_titles_next_replace_space_1}, q{$print_err} );

    #Trim strings in array;
    @sec_titles_next_replace_space_1 =
      map { trim($_) } @sec_titles_next_replace_space_1;

    #print_list_with_err( q{@sec_titles_next_replace_space_1},q{$print_err} );

    @sec_titles_next_replace_space_2 = @sec_titles_next_short_uc;
    s/[ ]/[\\s]/xsmg for @sec_titles_next_replace_space_2;

    #print_list_with_err( q{@sec_titles_next_replace_space_2}, q{$print_err} );

    #Trim strings in array;
    @sec_titles_next_replace_space_2 =
      map { trim($_) } @sec_titles_next_replace_space_2;

    #print_list_with_err( q{@sec_titles_next_replace_space_2}, q{$print_err} );

    #########################################################################;
    #Find Investmnt Objection Section;
    #########################################################################;

    @sec_comb_pats =
      map { q{(} . $sec_pat_2 . q{)} . q{.*?} . q{(} . "$_" . q{)} }
      @sec_titles_next_replace_space_2;
    print_list_with_err( q{@sec_comb_pats}, q{$print_err} );

#The first if statement below finds all cases where a match occurs into the array called @finds.
    @finds = ( $data =~ m{($sec_comb_rx)}xsmgi );

    #print_list_with_err( q{@finds}, q{$print_err} );

    #(INVESTMENT[\s]OBJECTIVE).*?(MANAGEMENT[\s]OF[\s]THE[\s]FUND)
    #(INVESTMENT[\s]OBJECTIVE).*?(MANAGEMENT[\s]OF[\s]THE[\s]FUND)

    #$sec=$finds[0];
    #$sec = 'ROLL TIDE';

    $sec = trim($sec);
    print_var_with_err( q{$sec}, q{$print_err} );

#This statement makes sure that any elements in the array contain words that are expected within the Item.
#@finds=grep(/$keywords/ismog,@finds);

#The variable audit_opinion is then given the first element in the array called finds.
#$audit_opinion=$finds[0];
#if($data=~m/($start_pat.*?$keywords.*?$end_pat)/ismo)
#{$audit_opinion=$1;}

    #Calculate the number of matches (i.e., the length of the finds array);
    $finds_size = @finds;

    #Print section to file or screen
    if ($OUTPUT_TO_FILE) {

        #Check to see if extract download folder exists.  If not, create it.
        if ( !-d "$output_dir$sep$dl_folder$sep$YEAR$sep$extract_folder" ) {
            mkdir "$output_dir$sep$dl_folder$sep$YEAR$sep$extract_folder"
              or croak( $create_err . $ERRNO );
        }

        open my $filehandle_close, '>',
          "$output_dir$sep$dl_folder$sep$YEAR$sep$extract_folder$sep$file"
          or croak( $open_err . $ERRNO );

#"$file\n$file_date\n$name\n$cik\n$sic\n$portfolios_count\n$html\n$finds_size\n$line\n$sec_num\n$sec_title\n$sec_num_next_1\n$sec_title_next\n"
        print {$filehandle_close}
          "$file\n$file_date\n$name\n$cik\n$sic\n$portfolios_count\n$data"
          or croak( $print_err . $ERRNO );

        close $filehandle_close
          or croak( $close_err . $ERRNO );
    }
    else {
        print "File:\t\t\t$file\n"
          or croak( $print_err . $ERRNO );
        print "Date:\t\t\t$file_date\n"
          or croak( $print_err . $ERRNO );
        print "Name:\t\t\t$name\n"
          or croak( $print_err . $ERRNO );
        print "CIK:\t\t\t$cik\n"
          or croak( $print_err . $ERRNO );
        print "SIC:\t\t\t$sic\n"
          or croak( $print_err . $ERRNO );
        print "Portfolios Match:\t$portfolios_count\n"
          or croak( $print_err . $ERRNO );
        print "HTML:\t\t\t$html\n"
          or croak( $print_err . $ERRNO );
        print "Matches:\t\t$finds_size\n"
          or croak( $print_err . $ERRNO );
        print "Line number:\t\t$line\n"
          or croak( $print_err . $ERRNO );
        print "Section number:\t\t$sec_num\n"
          or croak( $print_err . $ERRNO );
        print "Section title:\t\t$sec_title\n"
          or croak( $print_err . $ERRNO );
        print "Next section number:\t$sec_num_next_1\n"
          or croak( $print_err . $ERRNO );
        print "Next section title:\t$sec_title_next\n"
          or croak( $print_err . $ERRNO );

        #print "Elements:\t$#finds\n" or croak($print_err .$ERRNO);
        #print "\@finds:\n@finds"; print "@finds" or croak($print_err .$ERRNO);
        #print "\@finds[0]:\n"; print $finds[0] or croak($print_err .$ERRNO);
        #print "\@finds[1]:\n";print $finds[1] or croak($print_err .$ERRNO);

        #Print asterisks to separate filings
        print qq{\n}, $asterisk_str x $CONSOLE_WIDTH, qq{\n}
          or croak( $print_err . $ERRNO );
    }

    #Set to 1 if want to put in break for user input
    my $debug = 0;
    if ($debug) {
        print "Press enter to continue\n"
          or croak( $print_err . $ERRNO );
        my $debug_input = <>;
    }
}

#=====================================================================;
#END SCRIPT;
#=====================================================================;

#Start timer
my $end_run = Benchmark->new;
my $run_time = timediff( $end_run, $start_run );
print "Script execution time:\t" . timestr($run_time) . qq{\n}
  or croak( $print_err . $ERRNO );

#=====================================================================;
#SUBROUTINES;
#=====================================================================;
# Perl trim function to remove whitespace from the start and end of the string
sub trim {
    my $string = shift;
    $string =~ s/^\s+//xms;
    $string =~ s/\s+$//xms;
    return $string;
}

# Left trim function to remove leading whitespace
sub ltrim {
    my $string = shift;
    $string =~ s/^\s+//xms;
    return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim {
    my $string = shift;
    $string =~ s/\s+$//xms;
    return $string;
}

# Used in print functions
sub peek_above {
    my $name_peek_above = shift;
    return PadWalker::peek_my(2)->{$name_peek_above}
      // PadWalker::peek_our(2)->{$name_peek_above};
}

# Print variable with error messages
sub print_var_with_err {
    my ( $a, $b ) = @_;

    #use vars qw($a_eval $b_eval);
    #$a_eval = ${ peek_above $a};
    #$b_eval = ${ peek_above $b};
    my $a_eval = ${ peek_above $a};
    my $b_eval = ${ peek_above $b};
    print $a . qq{:\n} . $a_eval . qq{\n} or croak( $b_eval . $ERRNO );
    return;
}

# Print list with error messages
sub print_list_with_err {
    my ( $c, $d ) = @_;
    my @c_eval = @{ peek_above $c};
    my $d_eval = ${ peek_above $d};
    while ( my ( $index, $elem ) = each @c_eval ) {
        say $c . q{[} . $index . qq{]:\n} . $elem . qq{\n}
          or croak( $d_eval . $ERRNO );
    }
    return;
}
