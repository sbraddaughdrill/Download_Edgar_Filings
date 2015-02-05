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
#Program: 	     Daughdrill_read_filings_Extract_Items.plx;
#Version: 	     1.0;
#Author:         S. Brad Daughdrill;
#Date:		     10.30.2012;
#Purpose:	     This program is going to obtain certain text from EDGAR filings.  You can extract whatever text you are 
#                interested in by changing the regular expressions for the start and end strings below.
#Prerequisites:  1.) Download (http://www.activestate.com/activeperl/downloads) and install Perl to C:\usr
#                2.) Make sure all packages are up-to-date (in command prompt, type "ppm")
#                3.) Associate *.pl files with Perl
#                     - Start Command Prompt (Start >> Programs >> Accessories >> Right-click on Command Prompt >> Run as administrator)
#                     - Type "assoc .pl=PerlScript"
#                4.) Add .PL to your PATHEXT environment variable.
#                     - Start Command Prompt (Start >> Programs >> Accessories >> Right-click on Command Prompt >> Run as administrator)
#                     - Type "SETX PATHEXT %PATHEXT%;.PL"
#                5.) Execute Daughdrill_get_index_files.plx
#                6.) Execute Daughdrill_Download_Filings.plx
#Useage:	     1.) Type 'cd ' and then the value of codedirect below
#                2.) Type 'perl ' and then the name of the file
#=====================================================================;

#=====================================================================;
#SOURCE DIRECTORY;
#=====================================================================;
#my $codedirect="C:\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl";                                              # Office;
#my $codedirect="\\tsclient\\C\\Users\\bdaughdr\\Dropbox\\Research\\3rd-Year_Paper\\Perl";                                   # CoralSea from Office;
#my $codedirect="\\tsclient\\C\\Users\\S. Brad Daughdrill\\Documents\\My Dropbox\\Research\\3rd-Year_Paper\\Perl";           # CoralSea from Home;
my $codedirect="C:\\Users\\bdaughdr\\Google Drive\\Dropbox\\Dropbox\\Research\\3rd-Year_Paper\\Perl";                        # Office 2;
#my $codedirect="\\tsclient\\C\\Users\\bdaughdr\\Google Drive\\Dropbox\\Dropbox\\Research\\3rd-Year_Paper\\Perl";            # CoralSea from Office 2;
#my $codedirect="\\tsclient\\C\\Users\\S. Brad Daughdrill\\Google Drive\\Dropbox\\Dropbox\\Research\\3rd-Year_Paper\\Perl";  # CoralSea from Home 2;
#=====================================================================;

#=====================================================================;
#PROJECT ROOT DIRECTORY;
#=====================================================================;
my $projectrootdirectory="H:\\Research\\Mutual_Funds\\Perl";
#=====================================================================;

#=====================================================================;
#PARAMETERS;
#=====================================================================;

#If using windows, set to "\\" - if mac (or unix), set to "/";
my $slash='\\';

#Set to 1 if want to put in break for user input
my $debug = 1;
my $debuginput="";
#if ( $debug ) { print "Press enter to continue\n"; $debuginput = <>;}

#Set to 1 if want to output to file or 0 to screen
my $outputtofile = 1;

#Folder year
my $year=1994;

#The parent directory of the downloaded filings
#my $downloadfolder="10K";
my $downloadfolder="N-1A";
#The sub directory of the downloaded filings
my $originalfolder="original";
#The directory of the extracted filings
my $extractfolder="extract2";

#Specify the start of the text you are looking for. 
my $startstring='INVESTMENT OBJECTIVE';
#my $startstring='INVESTMENT OBJECTIVE AND POLICIES';
#my $startstring='Item 9';   #NOTE a strange case I</a>tem 9;
#my $startstring='((^\s*?)Item\s+[89]A[\.\-]?\s+Controls[^\d]*?procedure[^\d]*?\n)';

#Specify the start of the text you are looking for. You my need a different one for HTML versus text filings
my $startstringhtm='INVESTMENT OBJECTIVE';	
#my $startstringhtm='((>\s?|^\s*?)Item(&.{1,5};\s*)*\s*[89]A\.?\s*(<[^<]*>\s*)*(&.{1,5};\s*)*\.?(<[^<]*>\s*)*\s*Control[^\d]*?Procedure[^\d]*?(\n|<))';

#Specify the end of the text you are looking for.
my $endstring='\n\n';
#my $endstring='MANAGEMENT OF THE FUND';
#my $endstring='Item 10';
#my $endstring='((^\s*?)Item\s+(8A|9|9A|10)[\.\-]?[^\d]*?\n)';

#Specify the beginning of text you are looking for. You my need a different one for HTML versus text filings
my $endstringhtm='\n\n';
#my $endstringhtm='MANAGEMENT OF THE FUND';
#my $endstringhtm='((>\s*|^\s*)Item(&.{1,5};\s*)*\s*(8A|9A?|10)[\.\-]?\s*(&.{1,5};\s*)*[^\d]*?(\n|<))';

#Specify keywords/phrases you expect to find within the item (make sure the words phrases are not also in the start or end string)
my $keywords='(none|not\s*applicable|no\s*change|January|February|March|April|May|June|July|August|September|October|November|December)';

#=====================================================================;
#BEGIN SCRIPT;
print "Begin Script \n";
#=====================================================================;

#The following two steps open the directory containing the files you plan to read and then stores the name of each file in an array called @New1.
opendir(DIR1,"$projectrootdirectory$slash$downloadfolder$slash$year$slash$originalfolder")||die "Can't open directory";
my @New1=readdir(DIR1);

#We will now loop through each file.  The file names have been stored in the array called @New1;
foreach $file(@New1)
{
	#This prevents me from reading the first two entries in a directory . and ..;
	
	if ($file=~/^\./){next;}
	#Initialize the variable names.
	my $cik=-99;
	my $file_date=-99;
	my $name="";
	my $sic=-99;
	my $HTML=0;
	my $Audit_Opinion="Not Found";
	my $ao="Not Found";
	my $tree="Empty";
	my $data="";
	my $datafromstartstring="";
	
	my @finds=();
	my $findsSize=0;
	
	my $prev_lines=0;
	my $tag_lines=0;
	my $line=0;
	
	#Open the file and put the file in variable called $data
	#$data will contain the entire filing
	{
		#this step removes the default end of line character (\n) so the the entire file can be read in at once.
		local $/;
		open (SLURP, "$projectrootdirectory$slash$downloadfolder$slash$year$slash$originalfolder$slash"."$file")||die "can't open $file: $!"; 
		#read the contents into data
		$data = <SLURP>; 
	}
	#close the filehandle called SLURP
	close SLURP||die "cannot close $file: $!";
	
	#The following steps obtain basic data from the filings
	if($data=~m/<HTML>/i){$HTML=1;}
	#The $number variables contain the parts of the string that matched the capturing groups in the pattern for your last regex match if the match was successful.
	if($data=~m/^\s*FILED\s*AS\s*OF\s*DATE:\s*(\d*)/m){$file_date=$1;}               
	if($data=~m/^\s*COMPANY\s*CONFORMED\s*NAME:\s*(.*$)/m){$name=$1;}
	if($data=~m/^\s*CENTRAL\s*INDEX\s*KEY:\s*(\d*)/m){$cik=$1;}
	#if($data=~m/^\s*STANDARD\s*INDUSTRIAL\s*CLASSIFICATION:.*?\[(\d{4})/m){$sic=$1;}     #NOT WORKING;
	
	#The following steps extract the audit opinion (or whatever section of text you want) 
	#The first if statement determines whether the filing is in HTML format or plain text.

	if($HTML==0){
		
		#These steps are executed if it is a plain text document
		#We use the regular expressions $startstring and $endstring because they are specifically for nonhtml filings.
		#The first if statement below finds all cases where a match occurs into the array called @finds.  
		@finds=$data=~m/($startstring.*?$endstring)/ismog;
		
		#This statement makes sure that any elements in the array contain words that are expected within the Item.
		@finds=grep(/$keywords/ismog,@finds);
		#The variable Audit_Opinion is then given the first element in the array called finds.
		$Audit_Opinion=$finds[0];
		#if($data=~m/($startstring.*?$keywords.*?$endstring)/ismo)
		#{$Audit_Opinion=$1;}
	}
	else{

		#The same steps are repeated for HTML documents but  with a few subtle differences.  
		#First, we use different start and end strings. 
		@finds=$data=~m/($startstringhtm.*?$endstringhtm)/ismog;
		#This statement makes sure that any elements in the
		#array contain words that are expected within the Item.
		@finds=grep(/$keywords/ismog,@finds);
		$ao=$finds[0];
		#the following steps strip out any HTML tags, etc.
		$tree=HTML::TreeBuilder->new->parse($ao);
		$formatter=HTML::FormatText->new(leftmargin=> 0, rightmargin=>60);
		$Audit_Opinion=$formatter->format($tree);
		
	}

	#Calculate the number of matches (i.e., the length of the finds array);
	$findsSize = @finds;
	
	#DELETE THIS!!!
	print "File: \t\t $file\n";
	print "File Date: \t $file_date\n";
	print "Name: \t\t $name\n";
	print "CIK: \t\t $cik\n";
	print "SIC: \t\t $sic\n";
	print "HTML: \t\t $HTML\n";
	print "Matches: \t $findsSize\n";
	print "Line number: \t $line\n";
	#print "$Audit_Opinion \n";
	#print "Elements: \t $#finds \n";
	#print "\@finds:\n@finds"; print "@finds";
	#print "\@finds[0]:\n"; print $finds[0];
	#print "\@finds[1]:\n";print $finds[1];
	
	#Print asterisks to separate filings
	print "\n", "*" x 80, "\n" ;
	
	#Print section to file or screen
	if( $outputtofile ){
		#Check to see if extract download folder exists.  If not, create it.
		unless(-d "$projectrootdirectory$slash$downloadfolder$slash$year$slash$extractfolder"){
		mkdir("$projectrootdirectory$slash$downloadfolder$slash$year$slash$extractfolder") or die "Extract folder cannot be created: $!";}
			
		$outfiler=">$projectrootdirectory$slash$downloadfolder$slash$year$slash$extractfolder$slash$file";
			
		open(OUTPUT, "$outfiler") || die "Can't output to file: $!";
			
		print OUTPUT "$file\n";
		print OUTPUT "$file_date\n";
		print OUTPUT "$name\n";
		print OUTPUT "$cik\n";
		print OUTPUT "$sic\n";
		print OUTPUT "$HTML\n";
		print OUTPUT "$findsSize\n";
		print OUTPUT "$line\n";
		print OUTPUT "$Audit_Opinion\n" ;
			
		close(OUTPUT);
	}
	else{
		print "File: \t\t $file\n";
		print "File Date: \t $file_date\n";
		print "Name: \t\t $name\n";
		print "CIK: \t\t $cik\n";
		print "SIC: \t\t $sic\n";
		print "HTML: \t\t $HTML\n";
		print "Matches: \t $findsSize\n";
		print "Line number: \t $line\n";
		print "$Audit_Opinion\n";
			
		#Print asterisks to separate filings
		print "\n", "*" x 80, "\n" ;
	}
	
	#if ( $debug ) { print "Press enter to continue\n"; $debuginput = <>;}
	
}

#=====================================================================;
#END SCRIPT;
$end_run = new Benchmark;
$run_time = timediff($end_run, $start_run);
print ("Script execution took ", timestr($run_time));
#=====================================================================;
