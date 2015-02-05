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
#Program: 	     Daughdrill_read_filings_extract_blocks_of_text.plx;
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
my $outputtofile = 0;

#Folder year
my $year=1994;

#The parent directory of the downloaded filings
#my $downloadfolder="10K";
my $downloadfolder="N-1A";
#The sub directory of the downloaded filings
my $originalfolder="original";
#The directory of the extracted filings
my $extractfolder="extract";

#Specify the start of the text you are looking for.
my $startstring='((\d*|\d.*)\s*Investment\s*Objectives\S*)';
#my $startstring='((\d*|\d.*)?\s*Investment\s*Objectives\S*)';
#my $startstring='Investment Objective and Policies';
my $startstring='((^\s*?)((We\s*(have|were)\s*(audited\s*the\s*(Statement\s*of\s*Financial\s*Condition|consolidated|accompanying|combined|balance\s*sheets)|(completed\s*|engaged\s*to\s*perform)\s*an\s*integrated\s*audit))|In\s*our\s*opinion,\s*the\s*(consolidated|accompanying)))';
#my $startstring='((^\s*?)((?:We\s*(have|were)\s*(?:audited\s*the\s*(?:Statement\s*of\s*Financial\s*Condition|consolidated|accompanying|combined|balance\s*sheets)|(?:completed\s*|engaged\s*to\s*perform)\s*an\s*integrated\s*audit))|In\s*our\s*opinion,\s*the\s*(?:consolidated|accompanying)))';	

#Specify the start of the text you are looking for. You my need a different one for HTML versus text filings
my $startstringhtm='INVESTMENT OBJECTIVE';	
#my $startstringhtm='(((We\s*(have|were)\s*(audited\s*the\s*(Statement\s*of\s*Financial\s*Condition|consolidated|accompanying|combined|balance\s*sheets)|(completed\s*|engaged\s*to\s*perform)\s*an\s*integrated\s*audit))|In\s*our\s*opinion,\s*the\s*(consolidated|accompanying)))';	
#my $startstringhtm='(?:(?:(?:We\s*(?:have|were)\s*(?:audited\s*the\s*(?:Statement\s*of\s*Financial\s*Condition|consolidated|accompanying|combined|balance\s*sheets)|(?:completed\s*|engaged\s*to\s*perform)\s*an\s*integrated\s*audit))|In\s*our\s*opinion,\s*the\s*(?:consolidated|accompanying)))';

#Specify the end of the text you are looking for.
#my $endstring='((\d*|\d.*)\s*Investment\s*Objectives\S*)';
#my $endstring='\n\n';
my $endstring='MANAGEMENT OF THE FUND';
#my $endstring='((^\s*)/s/|^\s*(Date:\s*)?(\d{1,2}\s*)?((January|February|March|April|May|June|July|August|September|October|November|December))\s*(\d{1,2},)?\s*\d{4}(\s*$|,\s{0,3}except|\s*/s|\s*s/|\d{1,2}))';
#my $endstring='(?:(?:^\s*)/s/|^\s*(?:Date:\s*)?(?:\d{1,2}\s*)?(?:(?:January|February|March|April|May|June|July|August|September|October|November|December))\s*(?:\d{1,2},)?\s*\d{4}(?:\s*$|,\s{0,3}except|\s*/s|\s*s/|\d{1,2}))';

#Specify the beginning of text you are looking for. You my need a different one for HTML versus text filings
#my $endstringhtm='\n\n';
my $endstringhtm='MANAGEMENT OF THE FUND';
#my $endstringhtm='((>|^\s*)(/s/)?\s*(Date:\s*)?(\d{1,2}\s*)?(January|February|March|April|May|June|July|August|September|October|November|December))\s*(&\w+?;\s*)?(\d{1,2},)?\s*\d{4}(\s*$|\s*[,\(]\s{0,3}except|\s*with\s*respect\s*to\s*our\s*opinion|<\/P>|<BR>|\s{0,1}\<\/FONT\>|\d{1,2})';
#my $endstringhtm='(?:(?:>|^\s*)(/s/)?\s*(?:Date:\s*)?(\d{1,2}\s*)?(?:January|February|March|April|May|June|July|August|September|October|November|December))\s*(?:&\w+?;\s*)?(?:\d{1,2},)?\s*\d{4}(?:\s*$|\s*[,\(]\s{0,3}except|\s*with\s*respect\s*to\s*our\s*opinion|<\/P>|<BR>|\s{0,1}\<\/FONT\>|\d{1,2})';

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
		#These steps are executed if it is a plain text document;
		#We use the regular expressions $startstring and $endstring because they are specifically for nonhtml filings;
		#The first if statement below finds the start of the audit opinion
		#The start of the line plus the following 200 lines (or less) is extracted and retained in the variable $data ($data now only contains 200 lines of data beginning with the startstring)
		#A quick note on part of this regular expression -(?:[^\n]*\n){50,200}
		#(?: This part just tells perl not to save the information to its own variable (e.g., $2)
		#Next we we tell PERL to give the next 50 to 200 lines (it will get as many as it can so this is usually going to be 200).
		#[^\n]* means any character that is not a newline character.
		#\n is the newline character.
		#{50,200} just means 50 to 200 occurrences of the string.
		if($data=~m/($startstring(?:[^\n]*\n){50,200})/ismo)
		{
			$datafromstartstring=$1;
				
			#Determine the line number of $startstring.
			#use substr() as an "lvalue" to find number of lines before </tag>
			#Assuming lines are defined as sequences of non-newline characters terminated by newlines, count the number of newlines using the tr/// operator.
			#We add 1 to count an incomplete last line, and the string doesn't end with a newline.
				
			$prev_lines = substr($data, 0, $-[0]) =~ tr/\n// + 1;
			#$prev_lines = substr($data, 0, $-[0]) =~ tr/\n// + !/\n\z/;
			#$prev_lines = substr($datafromstartstring, 0, pos($datafromstartstring)) =~ tr/\n// + 1;
			#$prev_lines = substr($data, 0, pos($data)) =~ tr/\n// + !/\n\z/;
			#$prev_lines = substr($datafromstartstring, 0, pos($datafromstartstring));

			# adjust for newlines contained in the matched element itself
			#$tag_lines = $tag =~ tr/\n//;
			#$tag_lines = $datafromstartstring =~ tr/\n// + !/\n\z/;
				
			#Caculate final line
			$line = $prev_lines - $tag_lines;

			#Now we look for the end of the opinion.  
			#If it is found, we store everything in data up to the endstring plus 10 lines.
			#The extra 10 lines is just to be sure we pick up any additional notes, etc. 
			#If the end string is not found, the entire data variable is included in the data extraction.
			#This will include the startsring plus the next 200 lines.
			if($datafromstartstring=~m/(.*?$endstring(?:[^\n]*\n){1,10})/ismo){$Audit_Opinion=$1;}
			else{$Audit_Opinion=$datafromstartstring;}
		}
	}
	else{
		#The same steps are repeated for HTML documents but we just use the html start and endstrings.
		if($data=~m/($startstringhtm(?:[^\n]*\n){50,200})/ismo)
		{
			$datafromstartstring=$1;
			
			#Determine the line number of $startstring.
			$prev_lines = substr($data, 0, $-[0]) =~ tr/\n// + 1;
			$line = $prev_lines - $tag_lines;
			
			#Now we look for the end of the opinion. 
			if($data=~m/(.*?$endstringhtm(?:[^\n]*\n){1,10})/ismo){$ao=$1;}
			else{$ao=$datafromstartstring;}
			#the following steps strip out any HTML tags, etc.
			$tree=HTML::TreeBuilder->new->parse($ao);
			$formatter=HTML::FormatText->new(leftmargin=> 0, rightmargin=>60);
			$Audit_Opinion=$formatter->format($tree);
		}
	}
		
	#DELETE THIS!!!
	print "File: \t\t $file\n";
	print "File Date: \t $file_date\n";
	print "Name: \t\t $name\n";
	print "CIK: \t\t $cik\n";
	print "SIC: \t\t $sic\n";
	print "HTML: \t\t $HTML\n";
	print "Line number: \t $line\n";
	print "$Audit_Opinion\n";
	
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
		print "Line number: \t $line\n";
		print "$Audit_Opinion\n";
			
		#Print asterisks to separate filings
		print "\n", "*" x 80, "\n" ;
	}
}
	
#=====================================================================;
#END SCRIPT;
$end_run = new Benchmark;
$run_time = timediff($end_run, $start_run);
print ("Script execution took ", timestr($run_time));
#=====================================================================;