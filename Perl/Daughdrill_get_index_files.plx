#!/usr/bin/perl
use warnings;

#use strict;

use Benchmark;

$start_run = new Benchmark;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Net::FTP;
use Tie::File;
use Fcntl;
use HTML::Formatter;         #get the HTML-Format package from the package manager.
use HTML::TreeBuilder;       #get the HTML-TREE from the package manager
use HTML::FormatText;

#=====================================================================;
#SCRIPT DETAILS;
#=====================================================================;
#Program: 	     Daughdrill_get_index_files.plx;
#Version: 	     1.0;
#Author:         S. Brad Daughdrill;
#Date:		     10.30.2012;
#Purpose:	     This file downloads the index files from Edgar. Edgar has an index file for each quarter and 
#                year so you need to grab each one.  
#Prerequisites:  1.) Download (http://www.activestate.com/activeperl/downloads) and install Perl to C:\usr
#                2.) Make sure all packages are up-to-date (in command prompt, type "ppm")
#                3.) Associate *.pl files with Perl
#                     - Start Command Prompt (Start >> Programs >> Accessories >> Right-click on Command Prompt >> Run as administrator)
#                     - Type "assoc .pl=PerlScript"
#                4.) Add .PL to your PATHEXT environment variable.
#                     - Start Command Prompt (Start >> Programs >> Accessories >> Right-click on Command Prompt >> Run as administrator)
#                     - Type "SETX PATHEXT %PATHEXT%;.PL"
#Useage:	     1.) Type 'cd ' and then the value of codedirect below
#                2.) Type 'perl ' and then the name of the file
#=====================================================================;

#=====================================================================;
#SOURCE DIRECTORY;
#=====================================================================;
my $codedirect="C:\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl";                                              # Office;
#my $codedirect="\\tsclient\\C\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl";                                   # CoralSea from Office;
#my $codedirect="\\tsclient\\C\\Users\\S. Brad Daughdrill\\Documents\\My Dropbox\\Research\\3rd-Year_Paper\\Perl";           # CoralSea from Home;

#=====================================================================;

#=====================================================================;
#PROJECT ROOT DIRECTORY;
#=====================================================================;
my $projectrootdirectory="H:\\Research\\OLD_Mutual_Funds\\Data\\Perl";
#=====================================================================;

#=====================================================================;
#PARAMETERS;
#=====================================================================;

#If using windows, set to "\\" - if mac (or unix), set to "/";
my $slash='\\';

#First year you want index files for:
my $startyear=1993;
#Last year you want index files for:
my $endyear=2012;
#First qtr you want index files for (usually 1):
my $startqtr=1;
#Last qtr you want index files for (usually 4):
my $endqtr=4;
#Output folder:
my $indexfolder="full-index";

#=====================================================================;

#=====================================================================;
#BEGIN SCRIPT;
print "Begin Script \n";
#=====================================================================;

#Check to see if project root directory exists.  If not, create it.
unless(-d "$projectrootdirectory"){
mkdir("$projectrootdirectory") or die "Project root directory cannot be created: $!";}
#Check to see if index folder exists.  If not, create it.
unless(-d "$projectrootdirectory$slash$indexfolder"){
mkdir("$projectrootdirectory$slash$indexfolder") or die "Index folder cannot be created: $!";}

#get index files;
#FTP signin-
$ftp = Net::FTP->new("ftp.sec.gov", Debug => 0) or die "Cannot connect to some.host.name: $@";

#This provides your user name and password.
$ftp->login("anonymous",'-anonymous@') or die "Cannot login ", $ftp->message;

#Get files loop- The program will loop through each year specified.
#Note that the counter (yr) starts with a value equal to start year and increments by 1 each time through.  The loop terminates after the counter exceeds $endyear.
for($yr=$startyear;$yr<=$endyear;$yr++)
{
	if($yr<$endyear){$eqtr=4}else{$eqtr=$endqtr}
	for($QTR=$startqtr;$QTR<=$eqtr;$QTR++)
	{		
        #filetoget is the name of the file we are going to get from edgar. 
		#Edgar stores each file in its own year and qtr directory.
		#We change the directory by using the counter and qtr variables.
        $filetoget="/edgar/full-index/$yr/QTR$QTR/company.zip";
		
        #$fonly is the name (and location) we are giving the file to be downloaded.
		#We have to give it a unique year and quarter name so each file is not overwritten by the other.
        $fonly="$projectrootdirectory$slash$indexfolder$slash"."company$yr$QTR.zip";
		
        #fidx is the name of the file we are going to give to the file we unzip.
        $fidx="$projectrootdirectory$slash$indexfolder$slash"."company$yr$QTR.idx";
		
        #This tells the ftp module that we are going to ftp a binary file.
        $ftp->binary();
		
        #This is the actual excution of the get command (get file).
        $ftp->get("$filetoget", "$fonly") or  die "cannot connect: $@" ; #$QTR++, ftpsignin(),next;
		
		#Here we tell the zip module what file we are going to unzip.
		$zip = Archive::Zip->new($fonly);
		die 'read error' unless $zip->read( $fonly ) == AZ_OK;
		
		#Here we read the file we are unzipping.
		my $member1=$zip->read( $fonly );
		
		#Here we tell zip the exact member of the zip file that we want (there is only one in our case).
		my $member2=$zip->extractMember( 'company.idx' , $fidx );
	}
}
$ftp->quit;

#=====================================================================;
#END SCRIPT;
$end_run = new Benchmark;
$run_time = timediff($end_run, $start_run);
print ("Script execution took ", timestr($run_time));
#=====================================================================;
