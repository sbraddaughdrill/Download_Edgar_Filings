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
use strict;
use warnings;
use 5.014;
use vars qw/ $VERSION /;
$VERSION = '1.00';

#use re 'debug';
#use diagnostics;

#Modules
use English qw(-no_match_vars);
use Readonly;
use Benchmark;
use Mods;

#=====================================================================;
#INITIAL SETUP;
#=====================================================================;
my $source_directory =
'C:\\Users\\S. Brad Daughdrill\\Google Drive\\Dropbox\\Dropbox\\Research\\3rd-Year_Paper\\Perl'
  ;    # Home;

#my $source_directory='C:\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl';                                              # Office;
#my $source_directory='\\tsclient\\C\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl';                                   # CoralSea from Office;
#my $source_directory='\\tsclient\\C\\Users\\S. Brad Daughdrill\\Documents\\My Dropbox\\Research\\3rd-Year_Paper\\Perl';           # CoralSea from Home;
#my $source_directory='C:\\Users\\bdaughdr\\Google Drive\\Dropbox\\Dropbox\\Research\\3rd-Year_Paper\\Perl';                       # Office 2;
#my $source_directory='\\tsclient\\C\\Users\\bdaughdr\\Google Drive\\Dropbox\\Dropbox\\Research\\3rd-Year_Paper\\Perl';            # CoralSea from Office 2;
#my $source_directory='\\tsclient\\C\\Users\\S. Brad Daughdrill\\Google Drive\\Dropbox\\Dropbox\\Research\\3rd-Year_Paper\\Perl';  # CoralSea from Home 2;

my $project_root_directory = 'C:\\Perl_Test';    # Home;

#my $project_root_directory='H:\\Research\\Mutual_Funds\\Perl';   # Office;

#Common strings
my $empty_str    = q{};
my $blank_str    = q{ };
my $asterisk_str = q{*};

#Error messages
my $close_err_msg  = "Cannot close:\t";
my $create_err_msg = "Cannot create folder:\t";
my $open_err_msg   = "Cannot open:\t";
my $print_err_msg  = "Cannot print:\t";
my $eval_err_msg   = "Cannot evaluate:\t";

#Set the console size of a running console
Readonly my $CONSOLE_WIDTH  => 170;
Readonly my $CONSOLE_HEIGHT => 999;
eval { system "mode con cols=$CONSOLE_WIDTH lines=$CONSOLE_HEIGHT"; 1; } or do {
    if ($EVAL_ERROR) {
        error( $eval_err_msg . $EVAL_ERROR );
    }
};

#=====================================================================;
#VARIABLES TO CHANGE;
#=====================================================================;

#Folder year
Readonly my $YEAR => 1994;

#Set to 1 if want to output to file or 0 to screen
Readonly my $OUTPUT_TO_FILE => 0;

#The parent directory of the downloaded filings
my $download_folder = $empty_str;
$download_folder .= 'N-1A';

#$download_folder .= '10K';

#The sub directory of the downloaded filings
my $original_folder = $empty_str;
$original_folder .= 'original';

#The directory of the extracted filings
my $extract_folder = $empty_str;
$extract_folder .= 'extract3';

#If using windows, set to '\\' - if mac (or unix), set to '/';
my $slash = $empty_str;
$slash .= q{\\};

#=====================================================================;
#STRINGS FOR REGEX;
#=====================================================================;

my $date_str    = 'Filed as of Date:';
my $name_str    = 'Company Conformed Name:';
my $cik_str     = 'Central Index Key:';
my $sic_str     = 'Standard Industrial Classification:';
my $section_str = 'Investment Objective';

#=====================================================================;
#UPCASE STRINGS;
#=====================================================================;

my $date_str_u    = uc $date_str;
my $name_str_u    = uc $name_str;
my $cik_str_u     = uc $cik_str;
my $sic_str_u     = uc $sic_str;
my $section_str_u = uc $section_str;

#=====================================================================;
#REPLACE SPACES IN STRINGS WITH [\s]
#=====================================================================;

my $replace_space_pat = q{[ ]};
my $replace_space_rx  = qr{$replace_space_pat}xms;
my $replace_space_sub = q{[\\s]};

my $date_pat = $date_str_u =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $name_pat = $name_str_u =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $cik_pat = $cik_str_u =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $sic_pat = $sic_str_u =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $section_pat_1 = $section_str =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;
my $section_pat_2 = $section_str_u =~ s/($replace_space_rx)/$replace_space_sub/xmsgr;


$date_pat = trim($date_pat);
$name_pat = trim($name_pat);
$cik_pat = trim($cik_pat);
$sic_pat = trim($sic_pat);
$section_pat_1 = trim($section_pat_1);
$section_pat_2 = trim($section_pat_2);

#print "\$date_pat:\n" . $date_pat . qq{\n}
#  or croak( $print_err_msg . $ERRNO );
#print "\$name_pat:\n" . $name_pat . qq{\n}
#  or croak( $print_err_msg . $ERRNO );
#print "\$cik_pat:\n" . $cik_pat . qq{\n}
#  or croak( $print_err_msg . $ERRNO );
#print "\$sic_pat:\n" . $sic_pat . qq{\n}
#  or croak( $print_err_msg . $ERRNO );
#print "\$section_pat_1:\n" . $section_pat_1 . qq{\n}
#  or croak( $print_err_msg . $ERRNO ); 
#print "\$section_pat_2:\n" . $section_pat_2 . qq{\n}
#  or croak( $print_err_msg . $ERRNO ); 

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

#REGEX for filing date
my $date_comb_pat = $empty_str;
$date_comb_pat .= q{(?<=(};
$date_comb_pat .= $date_pat;
$date_comb_pat .= q{))};
#$date_pat .= '(?<=(FILED[\s]AS[\s]OF[\s]DATE:))';
$date_comb_pat .= '[\s]*?';
#$date_comb_pat .= '.*?';
$date_comb_pat .= '(\d+)';
my $date_rx = qr{$date_comb_pat}xms;

#REGEX for fund name
my $name_comb_pat = $empty_str;
$name_comb_pat .= q{(?<=(};
$name_comb_pat .= $name_pat;
$name_comb_pat .= q{))};
#$name_comb_pat .= '(?<=(COMPANY[\s]CONFORMED[\s]NAME:))';
$name_comb_pat .= '.*?';
$name_comb_pat .= '((^\s*?)(?=CENTRAL))';
my $name_rx = qr{$name_comb_pat}xms;

#REGEX for CIK
my $cik_comb_pat = $empty_str;
$cik_comb_pat .= q{(?<=(};
$cik_comb_pat .= $cik_pat;
$cik_comb_pat .= q{))};
#$cik_comb_pat .= '(?<=(CENTRAL[\s]INDEX[\s]KEY:))';
$cik_comb_pat .= '[\s]*?';
#$cik_comb_pat .= '.*?';
$cik_comb_pat .= '(\d+)';
my $cik_rx = qr{$cik_comb_pat}xms;

#REGEX for SIC
my $sic_comb_pat = $empty_str;
$sic_comb_pat .= q{(?<=(};
$sic_comb_pat .= $sic_pat;
$sic_comb_pat .= q{))};
#$sic_comb_pat .= '(?<=(STANDARD[\s]INDUSTRIAL[\s]CLASSIFICATION:))';
$sic_comb_pat .= '[\s]*?';
#$sic_comb_pat .= '.*?';
$sic_comb_pat .= '(\d+)';
my $sic_rx = qr{$sic_comb_pat}xms;

#REGEX for temporary section number
my $section_num_temp_comb_pat = $empty_str;
$section_num_temp_comb_pat .= '((?:(\S+\s+){1,30})';
$section_num_temp_comb_pat .= $section_pat_1;
#$section_num_temp_comb_pat .= $section_pat_2;
$section_num_temp_comb_pat .= q{)};
my $section_num_temp_rx = qr{$section_num_temp_comb_pat}xms;

#REGEX for section number
my $section_num_comb_pat = $empty_str;
$section_num_comb_pat .= '(\d+)(?!\D*\d)';
my $section_num_rx = qr{$section_num_comb_pat}xms;

#Specify the start of the text you are looking for.
#my $section_pat = $empty_str;
#$section_pat .= $section_pat_1;
#$section_pat .= 'Investment[\s]Objective';
#$section_pat .= 'INVESTMENT[\s]OBJECTIVE';
#$section_pat .= 'Investment[\s]Objective[\s]And[\s]Policies';
#$section_pat .= 'Item 9';    #NOTE a strange case I</a>tem 9;
#$section_pat .= '((^\s*?)Item\s+[89]A[\.\-]?\s+Controls[^\d]*?procedure[^\d]*?\n)';

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
print "Begin Script\n" or croak( $print_err_msg . $ERRNO );

#Start timer
my $start_run = Benchmark->new;

#Variables for each iteration
my $html                = 0;
my $file_date           = $empty_str;
my $cik                 = $empty_str;
my $sic                 = $empty_str;
my $name                = $empty_str;
my $audit_opinion       = $empty_str;
my $ao                  = $empty_str;
my $tree                = $empty_str;
my $data                = $empty_str;
my $data_from_start_str = $empty_str;

#my $outfiler="";
my @finds      = ();
my $finds_size = 0;
my $prev_lines = 0;
my $tag_lines  = 0;
my $line       = 0;
my $formatter  = $empty_str;

my $section_temp  = $empty_str;
my $section_title = $empty_str;

my $section_num        = $empty_str;
my $section_num_next_1 = 0;
my $section_num_next_2 = 0;

my $section_num_next_comb_pat             = $empty_str;
my $section_num_next_comb_pat2            = $empty_str;
my $section_title_replace_dot_pat         = $empty_str;
my $section_title_next_short_pat          = $empty_str;
my $section_title_next_replace_space_pat  = $empty_str;
my $section_title_next_replace_space_sub = $empty_str;
my $section_comb_pat                      = $empty_str;

my $section_num_next_comb_rx            = $empty_str;
my $section_num_next_comb_rx2           = $empty_str;
my $section_title_replace_dot_rx        = $empty_str;
my $section_title_next_short_rx         = $empty_str;
my $section_title_next_replace_space_rx = $empty_str;
my $section_comb_rx                     = $empty_str;

my $section_title_next_temp          = $empty_str;
my $section_title_next               = $empty_str;
my $section_title_replace_dot        = $empty_str;
my $section_title_next_replace_dot   = $empty_str;
my $section_title_next_short         = $empty_str;
my $section_title_next_short_u         = $empty_str;
my $section_title_next_replace_space_1 = $empty_str;
my $section_title_next_replace_space_2 = $empty_str;
my $section                          = $empty_str;

#The following two steps open the directory containing the files you plan to read and then stores the name of each file in an array called @new1.
opendir my $directory_open,
"$project_root_directory$slash$download_folder$slash$YEAR$slash$original_folder"
  or croak( $open_err_msg . $ERRNO );

my @new1 = ();
@new1 = readdir $directory_open;

#print "\$New1[0]:\t$New1[0]" or croak($print_err_msg .$ERRNO);
#print "\$New1[1]:\t$New1[1]" or croak($print_err_msg .$ERRNO);
#print "\$New1[2]:\t$New1[2]" or croak($print_err_msg .$ERRNO);

#We will now loop through each file.  The file names have been stored in the array called @new1;
#foreach my $file ( $new1[2] ) {
foreach my $file (@new1) {

   #This prevents me from reading the first two entries in a directory . and ..;
    if ( $file =~ m{$file_rx}xms ) { next; }

    #ReInitialize the variable names.
    $html                = 0;
    $file_date           = $empty_str;
    $cik                 = $empty_str;
    $sic                 = $empty_str;
    $name                = $empty_str;
    $audit_opinion       = $empty_str;
    $ao                  = $empty_str;
    $tree                = $empty_str;
    $data                = $empty_str;
    $data_from_start_str = $empty_str;

    #$outfiler=$empty_str;
    @finds      = ();
    $finds_size = 0;
    $prev_lines = 0;
    $tag_lines  = 0;
    $line       = 0;
    $formatter  = $empty_str;

    $section_temp  = $empty_str;
    $section_title = $empty_str;

    $section_num        = $empty_str;
    $section_num_next_1 = 0;
    $section_num_next_2 = 0;

    $section_num_next_comb_pat             = $empty_str;
    $section_num_next_comb_pat2            = $empty_str;
    $section_title_replace_dot_pat         = $empty_str;
    $section_title_next_short_pat          = $empty_str;
    $section_title_next_replace_space_pat  = $empty_str;
    $section_title_next_replace_space_sub = $empty_str;
    $section_comb_pat                      = $empty_str;

    $section_num_next_comb_rx            = $empty_str;
    $section_num_next_comb_rx2           = $empty_str;
    $section_title_replace_dot_rx        = $empty_str;
    $section_title_next_short_rx         = $empty_str;
    $section_title_next_replace_space_rx = $empty_str;
    $section_comb_rx                     = $empty_str;

    $section_title_next_temp          = $empty_str;
    $section_title_next               = $empty_str;
    $section_title_replace_dot        = $empty_str;
    $section_title_next_replace_dot   = $empty_str;
    $section_title_next_short         = $empty_str;
    $section_title_next_short_u         = $empty_str;
    $section_title_next_replace_space_1 = $empty_str;
    $section_title_next_replace_space_2 = $empty_str;
    $section                          = $empty_str;

    #Open the file and put the file in variable called $data
    #$data will contain the entire filing
    {
#This step removes the default end of line character (\n) so the the entire file can be read in at once and read the contents into data;
        local $INPUT_RECORD_SEPARATOR = undef;
        open my $filehandle_open, '<',
"$project_root_directory$slash$download_folder$slash$YEAR$slash$original_folder$slash"
          . "$file"
          or croak( $open_err_msg . $ERRNO );
        $data = <$filehandle_open>;
        close $filehandle_open
          or croak( $close_err_msg . $ERRNO );
    }

#The following steps obtain basic data from the filings
#The $number variables contain the parts of the string that matched the capturing groups in the pattern for your last regex match if the match was successful.
#/i makes the regex match case insensitive.
#/s enables "single-line mode". In this mode, the dot matches newlines.
#/m enables "multi-line mode". In this mode, the caret and dollar match before and after newlines in the subject string.
#/g is a looping modifier

    if ( $data =~ m{$html_rx}xims ) { $html = 1; }
    if ( $data =~ m{($date_rx)}xms ) {
        $file_date = trim($1);
    }
    if ( $data =~ m{($cik_rx)}xms ) {
        $cik = trim($1);
    }
    if ( $data =~ m{($sic_rx)}xms ) {
        $sic = trim($1);
    }
    if ( $data =~ m{($name_rx)}xms ) {
        $name = trim($1);
    }

#The following steps extract the audit opinion (or whatever section of text you want)
#The first if statement determines whether the filing is in HTML format or plain text.

    if ( $html == 0 ) {

        #These steps are executed if it is a plain text document

        #Find the section number
        if ( $data =~ m{($section_num_temp_rx)}xms ) {

            $section_temp = $1;

            if ( $section_temp =~ m{($section_num_rx)}xms ) {
                $section_num = $1;
            }
        }

        #Find the Section Title
        if ( $section_temp =~ m{((?<=($section_num)).*)}xsm ) {
            $section_title = $1;
        }

        #Find the next section in the TOC
        $section_num_next_1 = $section_num + 1;
        $section_num_next_2 = $section_num + 2;

        #Find the title of the next section in the TOC
        $section_num_next_comb_pat .= q{(?<=(} . $section_pat_1 .q{))};
        $section_num_next_comb_pat .= q{.*?};
        $section_num_next_comb_pat .=
          q{(} . $section_num . q{A|} . $section_num_next_1 . q{)};
        $section_num_next_comb_pat .= q{.*?};
        $section_num_next_comb_pat .=
          q{(?=} . $section_num_next_1 . q{A|} . $section_num_next_2 . q{)};
        $section_num_next_comb_rx = qr{$section_num_next_comb_pat}xms;
        if ( $data =~ m{($section_num_next_comb_rx)}xsm ) {
            $section_title_next_temp = $1;
        }
        $section_num_next_comb_pat2 .= q{(?<=} . $section_num_next_1 . q{).*};
        $section_num_next_comb_rx2 = qr{$section_num_next_comb_pat2}xms;
        if ( $section_title_next_temp =~ m{($section_num_next_comb_rx2)}xsm ) {
            $section_title_next = $1;
        }

        #Replace all dots in section title and next section title with spaces
        $section_title_replace_dot_pat = q{[.]};
        $section_title_replace_dot_rx  = qr{$section_title_replace_dot_pat}xms;
        $section_title_replace_dot =
          $section_title =~ s/($section_title_replace_dot_rx)/$blank_str/xmsgr;
        $section_title_next_replace_dot =
          $section_title_next =~
          s/($section_title_replace_dot_rx)/$blank_str/xmsgr;
        $section_title_replace_dot      = trim($section_title_replace_dot);
        $section_title_next_replace_dot = trim($section_title_next_replace_dot);
        print "\$section_title_next_replace_dot:\n"
          . $section_title_next_replace_dot . qq{\n}
          or croak( $print_err_msg . $ERRNO );

        #Create short title for next section
        $section_title_next_short_pat = '^.+?(?=([ ]{3,}|[;]|\n|\t|\r))';
        $section_title_next_short_rx  = qr{$section_title_next_short_pat}xms;
        if ( $section_title_next_replace_dot =~
            m{($section_title_next_short_rx)}xsm )
        {
            $section_title_next_short = $1;
        }
        $section_title_next_short = trim($section_title_next_short);
        print "\$section_title_next_short:\n"
          . $section_title_next_short . qq{\n}
          or croak( $print_err_msg . $ERRNO );

        #Upcase title of next section;
        $section_title_next_short_u = uc $section_title_next_short;

        #Replace spaces in $section_title_next_short with [\s]
        $section_title_next_replace_space_pat  = q{[ ]};
        $section_title_next_replace_space_rx =
          qr{$section_title_next_replace_space_pat}xms;
        $section_title_next_replace_space_sub = q{[\\s]};
        
        $section_title_next_replace_space_1 =
          $section_title_next_short =~
s/($section_title_next_replace_space_rx)/$section_title_next_replace_space_sub/xmsgr;

        $section_title_next_replace_space_2 =
          $section_title_next_short_u =~
s/($section_title_next_replace_space_rx)/$section_title_next_replace_space_sub/xmsgr;

        $section_title_next_replace_space_1 =
          trim($section_title_next_replace_space_1);
        $section_title_next_replace_space_2 =
          trim($section_title_next_replace_space_2);
          
        print "\$section_title_next_replace_space_1:\n"
          . $section_title_next_replace_space_1 . qq{\n}
          or croak( $print_err_msg . $ERRNO );
        print "\$section_title_next_replace_space_2:\n"
          . $section_title_next_replace_space_2 . qq{\n}
          or croak( $print_err_msg . $ERRNO );

        #Find Investmnt Objection Section
        $section_comb_pat .= q{(} . $section_pat_2 . q{)};
        $section_comb_pat .= q{.*?};
        $section_comb_pat .= q{(} . $section_title_next_replace_space_2 . q{)};
        $section_comb_rx = qr{$section_comb_pat}xmsi;
        print "\$section_comb_pat:\n" . $section_comb_pat . qq{\n}
          or croak( $print_err_msg . $ERRNO );
          
        #The first if statement below finds all cases where a match occurs into the array called @finds.
        @finds = ( $data =~ m{($section_comb_rx)}xsmgi );


#(INVESTMENT[\s]OBJECTIVE).*?(MANAGEMENT[\s]OF[\s]THE[\s]FUND)
#(INVESTMENT[\s]OBJECTIVE).*?(MANAGEMENT[\s]OF[\s]THE[\s]FUND)





        print "\$finds[0]:\n" . $finds[0] . qq{\n}
          or croak( $print_err_msg . $ERRNO );
        print "\$finds[1]:\n" . $finds[1] . qq{\n}
          or croak( $print_err_msg . $ERRNO );
        print "\$finds[2]:\n" . $finds[2] . qq{\n}
          or croak( $print_err_msg . $ERRNO );

        #$section=$finds[0];
        $section = 'ROLL TIDE';

        #$section = trim($section);
        print "\$Section:\n" . $section . qq{\n}
          or croak( $print_err_msg . $ERRNO );

        #print "\$1:\n" . $1 . qq{\n}
        #  or croak( $print_err_msg . $ERRNO );
        #print "\$2:\n" . $2 . qq{\n}
        #  or croak( $print_err_msg  . $ERRNO );
        #print "\$3:\n" . $3 . qq{\n}
        #  or croak( $print_err_msg  . $ERRNO );
        #print "\$&:\n" . $& . qq{\n}
        #  or croak( $print_err_msg . $ERRNO );


        #Remove <PAGE> and the page number;





#This statement makes sure that any elements in the array contain words that are expected within the Item.
#@finds=grep(/$keywords/ismog,@finds);

#The variable audit_opinion is then given the first element in the array called finds.
#$audit_opinion=$finds[0];
#if($data=~m/($start_pat.*?$keywords.*?$end_pat)/ismo)
#{$audit_opinion=$1;}

    }
    else {

#The same steps are repeated for HTML documents but  with a few subtle differences.
#First, we use different start and end strings.
#@finds=$data=~m/($start_pat_htm.*?$end_pat_htm)/ismog;
#@finds = $data =~ m{($start_pat_htm.*?$end_pat_htm)}xismog;

#This statement makes sure that any elements in the array contain words that are expected within the Item.
#@finds=grep(/$keywords/ismog,@finds);
#@finds=grep({$keywords}xismog,@finds);
#@finds = grep { /$keywords/ismog } @finds;
#@finds = egrep { /$keywords/ismog } @finds;
        @finds = egrep( m{$keywords}xismog, @finds );
        $ao = $finds[0];

        #the following steps strip out any HTML tags, etc.
        $tree = HTML::TreeBuilder->new->parse($ao);

        $formatter =
          HTML::FormatText->new( leftmargin => 0, rightmargin => 60 );
        $audit_opinion = $formatter->format($tree);

    }

    #Calculate the number of matches (i.e., the length of the finds array);
    $finds_size = @finds;

    #Print section to file or screen
    if ($OUTPUT_TO_FILE) {

        #Check to see if extract download folder exists.  If not, create it.
        if (
            !-d "$project_root_directory$slash$download_folder$slash$YEAR$slash$extract_folder"
          )
        {
            mkdir
"$project_root_directory$slash$download_folder$slash$YEAR$slash$extract_folder"
              or croak( $create_err_msg . $ERRNO );
        }

        open my $filehandle_close, '>',
"$project_root_directory$slash$download_folder$slash$YEAR$slash$extract_folder$slash$file"
          or croak( $open_err_msg . $ERRNO );
        print {$filehandle_close}
"$file\n$file_date\n$name\n$cik\n$sic\n$html\n$finds_size\n$line\n$section_num\n$section_title\n$section_num_next_1\n$section_title_next\n"
          or croak( $print_err_msg . $ERRNO );
        close $filehandle_close
          or croak( $close_err_msg . $ERRNO );
    }
    else {
        print "File:\t\t\t$file\n"
          or croak( $print_err_msg . $ERRNO );
        print "Date:\t\t\t$file_date\n"
          or croak( $print_err_msg . $ERRNO );
        print "Name:\t\t\t$name\n"
          or croak( $print_err_msg . $ERRNO );
        print "CIK:\t\t\t$cik\n"
          or croak( $print_err_msg . $ERRNO );
        print "SIC:\t\t\t$sic\n"
          or croak( $print_err_msg . $ERRNO );
        print "HTML:\t\t\t$html\n"
          or croak( $print_err_msg . $ERRNO );
        print "Matches:\t\t$finds_size\n"
          or croak( $print_err_msg . $ERRNO );
        print "Line number:\t\t$line\n"
          or croak( $print_err_msg . $ERRNO );
        print "Section number:\t\t$section_num\n"
          or croak( $print_err_msg . $ERRNO );
        print "Section title:\t\t$section_title\n"
          or croak( $print_err_msg . $ERRNO );
        print "Next section number:\t$section_num_next_1\n"
          or croak( $print_err_msg . $ERRNO );
        print "Next section title:\t$section_title_next\n"
          or croak( $print_err_msg . $ERRNO );

     #print "Elements:\t$#finds\n" or croak($print_err_msg .$ERRNO);
     #print "\@finds:\n@finds"; print "@finds" or croak($print_err_msg .$ERRNO);
     #print "\@finds[0]:\n"; print $finds[0] or croak($print_err_msg .$ERRNO);
     #print "\@finds[1]:\n";print $finds[1] or croak($print_err_msg .$ERRNO);

        #Print asterisks to separate filings
        print qq{\n}, $asterisk_str x $CONSOLE_WIDTH, qq{\n}
          or croak( $print_err_msg . $ERRNO );
    }

    #Set to 1 if want to put in break for user input
    my $debug = 1;
    if ($debug) {
        print "Press enter to continue\n"
          or croak( $print_err_msg . $ERRNO );
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
  or croak( $print_err_msg . $ERRNO );

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
