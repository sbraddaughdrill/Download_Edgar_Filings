#!/usr/bin/perl

# $Id: Daughdrill_trim_filings.plx;
# $Revision: 1 $
# $HeadURL: 1 $
# $Source: /Perl/Daughdrill_trim_filings.plx $
# $Date: 10.30.2012 $
# $Author: S. Brad Daughdrill $

#=====================================================================;
#SCRIPT DETAILS;
#=====================================================================;
# Purpose:       This program parses the HMTL and removes the pages numbers
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
use HTML::Element;
use HTML::Formatter;      #get the HTML-Format package from the package manager.
use HTML::Tree;
use HTML::TreeBuilder;    #get the HTML-TREE from the package manager
use HTML::FormatText;

#use Net::FTP;
#use Tie::File;

use List::MoreUtils qw(apply pairwise uniq);
use PadWalker qw();
use HTML::Parser;
use LWP::Simple;

#=====================================================================;
#INITIAL SETUP;
#=====================================================================;
#my $source_dir ='C:\\Users\\S. Brad Daughdrill\\Dropbox\\Research\\3rd-Year_Paper\\Perl';    # Home;

my $source_dir='C:\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl';                                              # Office;
#my $source_dir='\\tsclient\\C\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl';                                   # CoralSea from Office;
#my $source_dir='\\tsclient\\C\\Users\\S. Brad Daughdrill\\Documents\\My Dropbox\\Research\\3rd-Year_Paper\\Perl';           # CoralSea from Home;

#my $output_dir = 'C:\\Perl_Test';    # Home;

my $output_dir = 'H:\\Research\\Mutual_Funds\\Data\\Perl';    # Office;

#Common strings
my $empty_str    = q{};
my $blank_str    = q{ };
my $asterisk_str = q{*};
my $amp_str      = q{&};
my $quot_str     = q{"};
my $apost_str    = q{'};
my $dec_str      = q{.};
my $div_str      = q{÷};
my $gt_str       = q{>};
my $lt_str       = q{<};

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
Readonly my $YEAR => 2009;

#Set to 1 if want to output the original trimmed filings
Readonly my $OUTPUT_ORG_TRIM => 1;

#Set to 1 if want to output to file or 0 to screen
Readonly my $OUTPUT_TO_FILE => 0;

#Set the value for irrelevant numbers
Readonly my $TRASH_VALUE => -999;

#Set the max value for section numbers in TOC
Readonly my $TOC_CUTOFF => 30;

#The parent directory of the downloaded filings
my $dl_folder = $empty_str;
$dl_folder .= 'Filings';

#$dl_folder .= '10K';

#The sub directory of the downloaded filings
my $org_folder = $empty_str;
$org_folder .= 'original';

#The sub directory of the downloaded filings
my $org_trim_folder = $empty_str;
$org_trim_folder .= 'original_trim';

#If using windows, set to '\\' - if mac (or unix), set to '/';
my $sep = $empty_str;
$sep .= q{\\};

#=====================================================================;
#REPLACE SPACES IN STRINGS WITH [\s]
#=====================================================================;

my $replace_space_pat = q{[ ]};
my $replace_space_rx  = qr{$replace_space_pat}xms;
my $replace_space_sub = q{[\\s]};

#=====================================================================;
#CREATE REGEX PATTERNS AND COMPILE THEM;
#=====================================================================;

#REGEX for files
my $file_pat = $empty_str;
$file_pat .= '^[.]';
my $file_rx = qr{$file_pat}xms;

#REGEX for html
my $html_pat = $empty_str;
$html_pat .= '<HTML>';
my $html_rx = qr{$html_pat}xms;

#REGEX for <page>
my $page_pat_1 = $empty_str;
$page_pat_1 .= '(<PAGE>|(?<!\S\s)PAGE)';
$page_pat_1 .= '[ ]+?';
$page_pat_1 .= '(A-)?';
$page_pat_1 .= '(\d*|(M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})))';
my $page_rx_1  = qr{$page_pat_1}xmsi;
my $page_pat_2 = $empty_str;
$page_pat_2 .= '(A-)?';
$page_pat_2 .= '(\d*|(M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})))';
$page_pat_2 .= '[\s]*?';
$page_pat_2 .= '(<PAGE>|(?<!\S\s)PAGE)';
my $page_rx_2 = qr{$page_pat_2}xmsi;

#REGEX for &amp; (ampersand)
my $amp_pat_1 = $empty_str;
$amp_pat_1 .= '&amp;|&#38;';
my $amp_rx_1 = qr{$amp_pat_1}xmsi;

#REGEX for &nbsp; (non-breaking space)
my $nbsp_pat_1 = $empty_str;
$nbsp_pat_1 .= '&nbsp;|&#160;';
my $nbsp_rx_1 = qr{$nbsp_pat_1}xmsi;

#REGEX for &quot; (quotation mark)
my $quot_pat_1 = $empty_str;
$quot_pat_1 .= '&quot;|&#34;';
my $quot_rx_1 = qr{$quot_pat_1}xmsi;

#REGEX for &#39; (apostrophe)
my $apost_pat_1 = $empty_str;
$apost_pat_1 .= '&#39;';
my $apost_rx_1 = qr{$apost_pat_1}xmsi;

#REGEX for &#133; (decimal)
my $dec_pat_1 = $empty_str;
$dec_pat_1 .= '&#133;';
my $dec_rx_1 = qr{$dec_pat_1}xmsi;

#REGEX for &#133; (divide)
my $div_pat_1 = $empty_str;
$div_pat_1 .= '&divide;|&#247;';
my $div_rx_1 = qr{$div_pat_1}xmsi;

#REGEX for &#133; (greater than)
my $gt_pat_1 = $empty_str;
$gt_pat_1 .= '&gt;|&#62;';
my $gt_rx_1 = qr{$gt_pat_1}xmsi;

#REGEX for &#133; (less than)
my $lt_pat_1 = $empty_str;
$lt_pat_1 .= '&lt;|&#60;';
my $lt_rx_1 = qr{$lt_pat_1}xmsi;

#=====================================================================;
#BEGIN SCRIPT;
#=====================================================================;
print "Begin Script\n" or croak( $print_err . $ERRNO );

#Start timer
my $start_run = Benchmark->new;

#Variables for each iteration
my $data         = $empty_str;
my $data_no_html = $empty_str;
my $html         = 0;

my @data_no_html_array = ();
my $parser             = $empty_str;

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
    $data         = $empty_str;
    $data_no_html = $empty_str;
    $html         = 0;

    @data_no_html_array = ();
    $parser             = $empty_str;

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

#The first if statement determines whether the filing is in HTML format or plain text.
#If $html = 0, the document is in plain text
    if ( $data =~ m{$html_rx}xsmi ) { $html = 1; }

    if ( $html == 1 ) {
        print "HTML is 1 in " . $file . qq{\n};
        
    }
    else {
        print "HTML is 0 in " . $file . qq{\n};

    }

    #the following steps strip out any HTML tags, etc.
    @data_no_html_array = ();
    $parser = HTML::Parser->new( text_h => [ \@data_no_html_array, "text" ] );
    $parser->parse($data);

    for (@data_no_html_array) {
        $data_no_html .= $_->[0];
    }

    $data = $data_no_html;

    #########################################################################;
    #Remove <PAGE> and preceeding the page number;
    #########################################################################;
    $data = $data =~ s/($page_rx_1)/$empty_str/xmsgri;
    $data = $data =~ s/($page_rx_2)/$empty_str/xmsgri;
    $data = trim($data);

    #print_var_with_err(q{$data}, q{$print_err} );

    #########################################################################;
    #Remove HTML Special Characters
    #########################################################################;
    $data = $data =~ s/($amp_rx_1)/$amp_str/xmsgri;
    $data = $data =~ s/($nbsp_rx_1)/$empty_str/xmsgri;
    $data = $data =~ s/($quot_rx_1)/$quot_str/xmsgri;
    $data = $data =~ s/($apost_rx_1)/$apost_str/xmsgri;
    $data = $data =~ s/($dec_rx_1)/$dec_str/xmsgri;
    $data = $data =~ s/($div_rx_1)/$div_str/xmsgri;
    $data = $data =~ s/($gt_rx_1)/$gt_str/xmsgri;
    $data = $data =~ s/($lt_rx_1)/$lt_str/xmsgri;
    $data = trim($data);

    #print_var_with_err(q{$data}, q{$print_err} );

    #########################################################################;
    #Print section to file or screen;
    #########################################################################;
    if ($OUTPUT_ORG_TRIM) {

        #Check to see if extract download folder exists.  If not, create it.
        if ( !-d "$output_dir$sep$dl_folder$sep$YEAR$sep$org_trim_folder" ) {
            mkdir "$output_dir$sep$dl_folder$sep$YEAR$sep$org_trim_folder"
              or croak( $create_err . $ERRNO );
        }

        open my $filehandle_trim, '>',
          "$output_dir$sep$dl_folder$sep$YEAR$sep$org_trim_folder$sep$file"
          or croak( $open_err . $ERRNO );
        print {$filehandle_trim} "$data"
          or croak( $print_err . $ERRNO );
        close $filehandle_trim
          or croak( $close_err . $ERRNO );
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
