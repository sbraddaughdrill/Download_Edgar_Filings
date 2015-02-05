#!/usr/bin/perl
use warnings;

#use strict;

use Benchmark;

$start_run = new Benchmark;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Net::FTP;
use Tie::File;
use Fcntl;
use HTML::Formatter;      #get the HTML-Format package from the package manager.
use HTML::TreeBuilder;    #get the HTML-TREE from the package manager
use HTML::FormatText;

#=====================================================================;
#SCRIPT DETAILS;
#=====================================================================;
#Program: 	     Daughdrill_Download_Filings.plx;
#Version: 	     1.0;
#Author:         S. Brad Daughdrill;
#Date:		     10.30.2012;
#Purpose:	     This program reads the company.idx files and then files are downloaded to separate year directories
#Prerequisites:  1.) Download (http://www.activestate.com/activeperl/downloads) and install Perl to C:\usr
#                2.) Make sure all packages are up-to-date (in command prompt, type "ppm")
#                3.) Associate *.pl files with Perl
#                     - Start Command Prompt (Start >> Programs >> Accessories >> Right-click on Command Prompt >> Run as administrator)
#                     - Type "assoc .pl=PerlScript"
#                4.) Add .PL to your PATHEXT environment variable.
#                     - Start Command Prompt (Start >> Programs >> Accessories >> Right-click on Command Prompt >> Run as administrator)
#                     - Type "SETX PATHEXT %PATHEXT%;.PL"
#                5.) Execute Daughdrill_get_index_files.plx
#Useage:	     1.) Type 'cd ' and then the value of codedirect below
#                2.) Type 'perl ' and then the name of the file
#=====================================================================;

#=====================================================================;
#SOURCE DIRECTORY;
#=====================================================================;
my $codedirect =
  "C:\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl";    # Office;

#my $codedirect="\\tsclient\\C\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl";                                   # CoralSea from Office;
#my $codedirect="\\tsclient\\C\\Users\\S. Brad Daughdrill\\Documents\\My Dropbox\\Research\\3rd-Year_Paper\\Perl";           # CoralSea from Home;

#=====================================================================;

#=====================================================================;
#PROJECT ROOT DIRECTORY;
#=====================================================================;
my $projectrootdirectory = "H:\\Research\\OLD_Mutual_Funds\\Data\\Perl";    #Office;

#my $projectrootdirectory = 'C:\\Perl_Test';    # Home;

#=====================================================================;

#=====================================================================;
#PARAMETERS;
#=====================================================================;
#NOTE: YOU SHOULD RUN THIS PROGRAM ONE YEAR AT A TIME

#If using windows, set to "\\" - if mac (or unix), set to "/";
my $slash = '\\';

#Set to 1 if want to put in break for user input
my $debug      = 1;
my $debuginput = "";

#if ( $debug ) { print "Press enter to continue\n"; $debuginput = <>;}

#First year you want index files for:
my $startyear = 2008;

#Last year you want index files for:
my $endyear = 2008;

#The parent directory you are going to download filings to
#my $downloadfolder="N-1A";
my $downloadfolder = "Filings";

#The sub directory you are going to download filings to
my $originalfolder = "original";

#The file that will contain the filings you want to download.
my $outfile = "getfiles.txt";

#=====================================================================;
#BEGIN SCRIPT;
print "Begin Script \n";

#=====================================================================;

#Check to see if project root directory exists.  If not, create it.
unless ( -d "$projectrootdirectory" ) {
    mkdir("$projectrootdirectory")
      or die "Project root directory cannot be created: $!";
}

#Check to see if download folder exists.  If not, create it.
unless ( -d "$projectrootdirectory$slash$downloadfolder" ) {
    mkdir("$projectrootdirectory$slash$downloadfolder")
      or die "Parent download folder cannot be created: $!";
}

for ( $yr = $startyear ; $yr <= $endyear ; $yr++ ) {



    print "$yr \n";

    #Check to see if yr folder exists.  If not, create it.
    unless ( -d "$projectrootdirectory$slash$downloadfolder$slash$yr" ) {
        mkdir("$projectrootdirectory$slash$downloadfolder$slash$yr")
          or die "Year directory cannot be created: $!";
    }



       #Check to see if sub original download folder exists.  If not, create it.
        unless (
            -d "$projectrootdirectory$slash$downloadfolder$slash$yr$slash$originalfolder"
          )
        {
            mkdir(
"$projectrootdirectory$slash$downloadfolder$slash$yr$slash$originalfolder"
            ) or die "Original download folder cannot be created: $!";
        }

      #Open the directory and get put the names of all files into the array @old
        opendir( DIR,
"$projectrootdirectory$slash$downloadfolder$slash$yr$slash$originalfolder"
        ) || die "Can't open directory";
        @Old = readdir(DIR);

#The tie statement assigns the file containing the files you want to download to the array @New1.
        tie(
            @New1,
            Tie::File,
            "$projectrootdirectory$slash$downloadfolder$slash$yr$slash$outfile",
            mode => O_RDWR
        ) or die "Cannot tie file BOO: $!n";

 #checks to see what files on the current index listing are not in the directory
 #defines a hash called seen.
        %seen = ();

        #defines an array called @aonly.
        @aonly = ();

        #build lookup table.  This step is building a lookup table(hash).
        #each filename (from OLD) has a value of 1 assigned to it.
        foreach $item (@Old) { $seen{$item} = 1 }

#for each item in the New1 array, which we got from the txt file containing all the files we want to download, add it to the array, @aonly, as long is it is not already in the current directory.
#We do this so we don't download a file we have already downloaded.
        foreach $item (@New1) {
            $item =~ /(edgar\/data\/.*\/)(.*\.txt)/;
            unless ( $seen{$2} ) {
                push( @aonly, $item );
            }
        }

#downloads all the files in the @oanly array which are the files not in the directory
        ftpsignin();
        foreach $filetoget (@aonly) {

            #$filetoget=trim($filetoget);
            $fullfile = "/$filetoget";
            $fonly    = $filetoget;

            #Don't forget to put your directory in here.
            $fonly =~
s/.*\/(.*)/$projectrootdirectory$slash$downloadfolder$slash$yr$slash$originalfolder$slash$1/;
            $ftp->get( "$fullfile", "$fonly" )
              or warn "can't get file", ftpsignin(),
              next;    # "cannot get file",$ftp->message, next;
        }
        $ftp->quit;



    #end of year loop
}

#=====================================================================;
#END SCRIPT;
$end_run = new Benchmark;
$run_time = timediff( $end_run, $start_run );
print( "Script execution took ", timestr($run_time) );

#=====================================================================;

#ftpsignin subroutine
sub ftpsignin {
    use Net::FTP;
    $ftp = Net::FTP->new( "ftp.sec.gov", Debug => 0 )
      or die "Cannot connect to some.host.name: $@";
    $ftp->login( "anonymous", '-anonymous@' )
      or next;    #die "Cannot login ", $ftp->message;
}

#trim subroutine
sub trim {
    my $new_phrase;
    my $phrase = shift(@_);
    $phrase =~ s/^\s+//;
    $phrase =~ s/\s+$//;
    $new_phrase = "$phrase";
    return "$new_phrase";
}