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

#Set the console size of a running console
Readonly my $CONSOLE_WIDTH  => 120;
Readonly my $CONSOLE_HEIGHT => 999;
eval { system "mode con cols=$CONSOLE_WIDTH lines=$CONSOLE_HEIGHT"; 1; } or do {
    if ($EVAL_ERROR) {
        error( 'Cannot adjust conolse width' . qq{\t} . $EVAL_ERROR );
    }
};

#=====================================================================;
#VARIABLES TO CHANGE;
#=====================================================================;

#Folder year
Readonly my $YEAR => 1994;

#Number of asterisks to print
Readonly my $ASTERISKS_COUNT => 120;

#Set to 1 if want to output to file or 0 to screen
Readonly my $OUTPUT_TO_FILE => 0;

#If using windows, set to '\\' - if mac (or unix), set to '/';
my $slash = q{\\};

#The parent directory of the downloaded filings
#my $download_folder='10K';
my $download_folder = 'N-1A';

#The sub directory of the downloaded filings
my $original_folder = 'original';

#The directory of the extracted filings
my $extract_folder = 'extract3';

#Strings for fund name
my $name_str_1 = '(?<=(COMPANY[\s]CONFORMED[\s]NAME:))';
my $name_str_2 = '.*?';
my $name_str_3 = '((^\s*?)(?=CENTRAL))';

#Strings for filing date
my $date_str_1 = '(?<=(FILED[\s]AS[\s]OF[\s]DATE:))';
my $date_str_2 = '.*?';
my $date_str_3 = '(\d+)';

#Strings for CIK
my $cik_str_1 = '(?<=(CENTRAL[\s]INDEX[\s]KEY:))';
my $cik_str_2 = '.*?';
my $cik_str_3 = '(\d+)';

#Strings for SIC
my $sic_str_1 = '(?<=(STANDARD[\s]INDUSTRIAL[\s]CLASSIFICATION:))';
my $sic_str_2 = '.*?';
my $sic_str_3 = '(\d*)';

#Strings for Investment Objective in TOC
my $section_num_str_1 = '((?:(\S+\s+){1,30})Investment[\s]Objective)';

my $section_num_str_2 = '(\d+)(?!\D*\d)';

#Strings for next section after Investment Objective in TOC
my $section_num_str_next_1 = '(?<=(Investment[\s]Objective))';
my $section_num_str_next_2 = '.*?';

#Specify the start of the text you are looking for.
my $start_string = '(\s*Investment\s*Objective\S*)';

#my $start_string='INVESTMENT OBJECTIVE AND POLICIES';
#my $start_string='Item 9';   #NOTE a strange case I</a>tem 9;
#my $start_string='((^\s*?)Item\s+[89]A[\.\-]?\s+Controls[^\d]*?procedure[^\d]*?\n)';

#Specify the start of the text you are looking for. You my need a different one for HTML versus text filings
my $start_string_htm =
'((>\s?|^\s*?)Item(&.{1,5};\s*)*\s*[89]A\.?\s*(<[^<]*>\s*)*(&.{1,5};\s*)*\.?(<[^<]*>\s*)*\s*Control[^\d]*?Procedure[^\d]*?(\n|<))';

#Specify the end of the text you are looking for.
my $end_string = qq{\n};

#my $end_string='MANAGEMENT OF THE FUND';
#my $end_string='Item 10';
#my $end_string='((^\s*?)Item\s+(8A|9|9A|10)[\.\-]?[^\d]*?\n)';

#Specify the beginning of text you are looking for. You my need a different one for HTML versus text filings
my $end_string_htm = 'MANAGEMENT OF THE FUND';

#my $end_string_htm='((>\s*|^\s*)Item(&.{1,5};\s*)*\s*(8A|9A?|10)[\.\-]?\s*(&.{1,5};\s*)*[^\d]*?(\n|<))';

#Specify keywords/phrases you expect to find within the item (make sure the words phrases are not also in the start or end string)
my $keywords =
'(none|not\s*applicable|no\s*change|January|February|March|April|May|June|July|August|September|October|November|December)';

#=====================================================================;
#VARIABLES TO REMAIN CONSTANT;
#=====================================================================;
#Compile REGEX strings
my $name_str_all          = qr{$name_str_1 . $name_str_2 . $name_str_3}xms;
my $date_str_all          = qr{$date_str_1 . $date_str_2 . $date_str_3}xms;
my $cik_str_all           = qr{$cik_str_1 . $cik_str_2 . $cik_str_3}xms;
my $sic_str_all           = qr{$sic_str_1 . $sic_str_2 . $sic_str_3}xms;
my $section_num_str_all_1 = qr{$section_num_str_1}xms;
my $section_num_str_all_2 = qr{$section_num_str_2}xms;    #Common strings
my $empty_string          = q{};
my $blank_string          = q{ };
my $asterisk_string       = q{*};

#Error messages
my $close_err_msg  = 'Cannot close:';
my $create_err_msg = 'Cannot create folder:';
my $open_err_msg   = 'Cannot open:';
my $print_err_msg  = 'Cannot print:';
my $eval_err_msg   = 'Cannot evaluate:';

#Variables for each iteration
my $cik                    = 0;
my $file_date              = 0;
my $sic                    = 0;
my $html                   = 0;
my $name                   = $empty_string;
my $audit_opinion          = $empty_string;
my $ao                     = $empty_string;
my $tree                   = $empty_string;
my $data                   = $empty_string;
my $data_from_start_string = $empty_string;

#my $outfiler="";
my @new1                           = ();
my @finds                          = ();
my $finds_size                     = 0;
my $prev_lines                     = 0;
my $tag_lines                      = 0;
my $line                           = 0;
my $formatter                      = $empty_string;
my $section_temp                   = $empty_string;
my $section_num                    = $empty_string;
my $section_title                  = $empty_string;
my $section_num_next_1             = 0;
my $section_num_next_2             = 0;
my $section_title_next             = $empty_string;
my $section_num_str_next_temp1     = $empty_string;
my $section_num_str_next_temp2     = $empty_string;
my $section_num_str_next_temp3     = $empty_string;
my $section_num_str_next_temp_comb = $empty_string;
my $section_num_str_next_all       = $empty_string;

#Variables for script time
my $start_run = 0;
my $end_run   = 0;
my $run_time  = 0;

#=====================================================================;
#BEGIN SCRIPT;
#=====================================================================;
print "Begin Script\n" or croak( $print_err_msg . qq{\t} . $ERRNO );

#Start timer
$start_run = Benchmark->new;

#The following two steps open the directory containing the files you plan to read and then stores the name of each file in an array called @new1.
#opendir my $directory_open,"$project_root_directory$slash$download_folder$slash$YEAR$slash$original_folder" or croak("Cannot open directory: $!\n");
opendir my $directory_open,
"$project_root_directory$slash$download_folder$slash$YEAR$slash$original_folder"
  or croak( $open_err_msg . qq{\t} . $ERRNO );

@new1 = readdir $directory_open;

#We will now loop through each file.  The file names have been stored in the array called @new1;

#print "\$New1[0]:\t$New1[0]" or croak($print_err_msg.qq{\t}.$ERRNO);
#print "\$New1[1]:\t$New1[1]" or croak($print_err_msg.qq{\t}.$ERRNO);
#print "\$New1[2]:\t$New1[2]" or croak($print_err_msg.qq{\t}.$ERRNO);

#foreach my $file ( $new1[2] ) {
foreach my $file (@new1) {

   #This prevents me from reading the first two entries in a directory . and ..;
   #if ($file=~/^\./){next;}
   #if ($file=~m{^\.}x){next;}
   #if ($file=~m{^[.]}x){next;}
    if ( $file =~ m{^[.]}xms ) { next; }

    #ReInitialize the variable names.
    $cik                    = 0;
    $file_date              = 0;
    $sic                    = 0;
    $html                   = 0;
    $name                   = $empty_string;
    $audit_opinion          = $empty_string;
    $ao                     = $empty_string;
    $tree                   = $empty_string;
    $data                   = $empty_string;
    $data_from_start_string = $empty_string;

    #$outfiler=$empty_string;
    @finds                          = ();
    $finds_size                     = 0;
    $prev_lines                     = 0;
    $tag_lines                      = 0;
    $line                           = 0;
    $section_temp                   = $empty_string;
    $section_title                  = $empty_string;
    $section_num                    = $empty_string;
    $section_num_next_1             = 0;
    $section_num_next_2             = 0;
    $section_num_str_next_temp1     = $empty_string;
    $section_num_str_next_temp2     = $empty_string;
    $section_num_str_next_temp3     = $empty_string;
    $section_num_str_next_temp_comb = $empty_string;
    $section_title_next             = $empty_string;

    #Open the file and put the file in variable called $data
    #$data will contain the entire filing
    {
#This step removes the default end of line character (\n) so the the entire file can be read in at once and read the contents into data;
        local $INPUT_RECORD_SEPARATOR = undef;
        open my $filehandle_open, '<',
"$project_root_directory$slash$download_folder$slash$YEAR$slash$original_folder$slash"
          . "$file"
          or croak( $open_err_msg . qq{\t} . $ERRNO );
        $data = <$filehandle_open>;
        close $filehandle_open
          or croak( $close_err_msg . qq{\t} . $ERRNO );
    }

#The following steps obtain basic data from the filings
#The $number variables contain the parts of the string that matched the capturing groups in the pattern for your last regex match if the match was successful.
#/s: makes . match \n too.
#/m: makes ^ and $ match next to embedded \n in the string.

    if ( $data =~ m{<HTML>}xims ) { $html = 1; }
    if ( $data =~ m{($date_str_all)}xms ) {
        $file_date = trim($1);
    }
    if ( $data =~ m{($cik_str_all)}xms ) {
        $cik = trim($1);
    }
    if ( $data =~ m{($sic_str_all)}xms ) {
        $sic = trim($1);
    }
    if ( $data =~ m{($name_str_all)}xms ) {
        $name = trim($1);
    }

#The following steps extract the audit opinion (or whatever section of text you want)
#The first if statement determines whether the filing is in HTML format or plain text.

    if ( $html == 0 ) {

        #Find the Section number
        if ( $data =~ m{($section_num_str_all_1)}xms ) {

            #print "\$1:\n" . $1 . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );
            #print "\$2:\n" . $2 . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );
            #print "\$3:\n" . $3 . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );
            #print "\$&:\n" . $& . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );

            $section_temp = $1;

            if ( $section_temp =~ m{($section_num_str_all_2)}xms ) {

                #print "\$1:\n" . $1 . qq{\n}
                #  or croak( $print_err_msg . qq{\t} . $ERRNO );
                #print "\$2:\n" . $2 . qq{\n}
                #  or croak( $print_err_msg . qq{\t} . $ERRNO );
                #print "\$3:\n" . $3 . qq{\n}
                #  or croak( $print_err_msg . qq{\t} . $ERRNO );
                #print "\$&:\n" . $& . qq{\n}
                #  or croak( $print_err_msg . qq{\t} . $ERRNO );

                $section_num = $1;

            }
        }

        #Find the Section number
        if ( $data =~ m{($section_num_str_all_1)}xms ) {

            #print "\$1:\n" . $1 . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );
            #print "\$2:\n" . $2 . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );
            #print "\$3:\n" . $3 . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );
            #print "\$&:\n" . $& . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );

            $section_temp = $1;

            if ( $section_temp =~ m{($section_num_str_all_2)}xms ) {

                #print "\$1:\n" . $1 . qq{\n}
                #  or croak( $print_err_msg . qq{\t} . $ERRNO );
                #print "\$2:\n" . $2 . qq{\n}
                #  or croak( $print_err_msg . qq{\t} . $ERRNO );
                #print "\$3:\n" . $3 . qq{\n}
                #  or croak( $print_err_msg . qq{\t} . $ERRNO );
                #print "\$&:\n" . $& . qq{\n}
                #  or croak( $print_err_msg . qq{\t} . $ERRNO );

                $section_num = $1;

            }
        }

        #Find the Section Title
        if ( $section_temp =~ m{((?<=($section_num)).*)}xsmi ) {

            #print "\$1:\n" . $1 . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );
            #print "\$2:\n" . $2 . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );
            #print "\$3:\n" . $3 . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );
            #print "\$&:\n" . $& . qq{\n}
            #  or croak( $print_err_msg . qq{\t} . $ERRNO );

            $section_title = $1;

        }

        #Find the next section in the table of contents
        $section_num_next_1 = $section_num + 1;
        $section_num_next_2 = $section_num + 2;

        #Create REGEX for next section
        $section_num_str_next_temp1 =
          $section_num_str_next_1 . $section_num_str_next_2;
        $section_num_str_next_temp2 =
          '(' . $section_num_next_1 . ')' . $section_num_str_next_2;
        $section_num_str_next_temp3 =
          '((^\s*?)(?=' . $section_num_next_2 . '))';
        $section_num_str_next_temp_comb =
            $section_num_str_next_temp1
          . $section_num_str_next_temp2
          . $section_num_str_next_temp3;

        $section_num_str_next_all = qr{$section_num_str_next_temp_comb}xms;

        #PRINT EACH OF THESE VARIABLES FOR TESTING!!
        print "\$section_num_next_1:\n" . $section_num_next_1 . qq{\n}
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "\$section_num_next_2:\n" . $section_num_next_2 . qq{\n}
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "\$section_num_str_next_temp1:\n"
          . $section_num_str_next_temp1 . qq{\n}
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "\$section_num_str_next_temp2:\n"
          . $section_num_str_next_temp2 . qq{\n}
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "\$section_num_str_next_temp3:\n"
          . $section_num_str_next_temp3 . qq{\n}
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "\$section_num_str_next_temp_comb:\n"
          . $section_num_str_next_temp_comb . qq{\n}
          or croak( $print_err_msg . qq{\t} . $ERRNO );

        #Find the Section Title

        #if ( $section_temp =~ m{($section_num_str_next_temp_comb)}xsm ) {
        if ( $data =~ m{($section_num_str_next_all)}xsm ) {
            print "\$1:\n" . $1 . qq{\n}
              or croak( $print_err_msg . qq{\t} . $ERRNO );
            print "\$2:\n" . $2 . qq{\n}
              or croak( $print_err_msg . qq{\t} . $ERRNO );
            print "\$3:\n" . $3 . qq{\n}
              or croak( $print_err_msg . qq{\t} . $ERRNO );
            print "\$&:\n" . $& . qq{\n}
              or croak( $print_err_msg . qq{\t} . $ERRNO );

            $section_title_next = 'ROLL TIDE';

            #$section_title_next = $1;

        }

#These steps are executed if it is a plain text document
#We use the regular expressions $start_string and $end_string because they are specifically for nonhtml filings.
#The first if statement below finds all cases where a match occurs into the array called @finds.
#/i makes the regex match case insensitive.
#/s enables "single-line mode". In this mode, the dot matches newlines.
#/m enables "multi-line mode". In this mode, the caret and dollar match before and after newlines in the subject string.
#/g is a looping modifier
#@finds=($data=~m/($start_string.*?$end_string)/ismog);
#@finds=($data=~m/($start_string.*?$end_string)/ismog);

#This statement makes sure that any elements in the array contain words that are expected within the Item.
#@finds=grep(/$keywords/ismog,@finds);
#The variable audit_opinion is then given the first element in the array called finds.
#$audit_opinion=$finds[0];
#if($data=~m/($start_string.*?$keywords.*?$end_string)/ismo)
#{$audit_opinion=$1;}

    }
    else {

#The same steps are repeated for HTML documents but  with a few subtle differences.
#First, we use different start and end strings.
#@finds=$data=~m/($start_string_htm.*?$end_string_htm)/ismog;
        @finds = $data =~ m{($start_string_htm.*?$end_string_htm)}xismog;

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
              or croak( $create_err_msg . qq{\t} . $ERRNO );
        }

        open my $filehandle_close, '>',
"$project_root_directory$slash$download_folder$slash$YEAR$slash$extract_folder$slash$file"
          or croak( $open_err_msg . qq{\t} . $ERRNO );
        print {$filehandle_close}
"$file\n$file_date\n$name\n$cik\n$sic\n$html\n$finds_size\n$line\n$section_num\n$section_title\n$section_num_next_1\n$section_title_next\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        close $filehandle_close
          or croak( $close_err_msg . qq{\t} . $ERRNO );
    }
    else {
        print "File:\t\t\t$file\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "Date:\t\t\t$file_date\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "Name:\t\t\t$name\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "CIK:\t\t\t$cik\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "SIC:\t\t\t$sic\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "HTML:\t\t\t$html\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "Matches:\t\t$finds_size\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "Line number:\t\t$line\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "Section number:\t\t$section_num\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "Section title:\t\t$section_title\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "Next section number:\t$section_num_next_1\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        print "Next section title:\t$section_title_next\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );

#print "Elements:\t$#finds\n" or croak($print_err_msg.qq{\t}.$ERRNO);
#print "\@finds:\n@finds"; print "@finds" or croak($print_err_msg.qq{\t}.$ERRNO);
#print "\@finds[0]:\n"; print $finds[0] or croak($print_err_msg.qq{\t}.$ERRNO);
#print "\@finds[1]:\n";print $finds[1] or croak($print_err_msg.qq{\t}.$ERRNO);

        #Print asterisks to separate filings
        print qq{\n}, $asterisk_string x $ASTERISKS_COUNT, qq{\n}
          or croak( $print_err_msg . qq{\t} . $ERRNO );
    }

    #Set to 1 if want to put in break for user input
    my $debug = 0;
    if ($debug) {
        print "Press enter to continue\n"
          or croak( $print_err_msg . qq{\t} . $ERRNO );
        my $debug_input = <>;
    }
}

#=====================================================================;
#END SCRIPT;
#=====================================================================;

#Start timer
$end_run = Benchmark->new;
$run_time = timediff( $end_run, $start_run );
print "Script execution time:\t" . timestr($run_time) . qq{\n}
  or croak( $print_err_msg . qq{\t} . $ERRNO );

#=====================================================================;
#SUBROUTINES;
#=====================================================================;
# Perl trim function to remove whitespace from the start and end of the string
sub trim {
    my $string = shift;
    $string =~ s/^\s+//sxm;
    $string =~ s/\s+$//sxm;
    return $string;
}

# Left trim function to remove leading whitespace
sub ltrim {
    my $string = shift;
    $string =~ s/^\s+//sxm;
    return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim {
    my $string = shift;
    $string =~ s/\s+$//sxm;
    return $string;
}
