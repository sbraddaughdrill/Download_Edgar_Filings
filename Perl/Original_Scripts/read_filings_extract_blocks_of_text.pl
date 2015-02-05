#!/usr/bin/perl -w
#use strict;
# This program extracts data from an SEC filing, including chunks of text
use Benchmark;
#get the HTML-Format package from the package manager.
use HTML::Formatter;
#get the HTML-TREE from the package manager
use HTML::TreeBuilder;
use HTML::FormatText;
$startTime = new Benchmark;


#This program is going to obtain and extract the entire audit opinion but you can
#extract whatever text you are interested in by changing the regular expressions for the start
#and end strings below.

#This program was written by Andy Leone, May 15 2007 and updated  July 25, 2008.
#You are free to use this program for your own use.  My only request is
#that you make an acknowledgement in any research manuscripts that
#benefit from the program.


my $startstring='((^\s*?)((We\s*(have|were)\s*(audited\s*the\s*(Statement\s*of\s*Financial\s*Condition|consolidated|accompanying|combined|balance\s*sheets)|(completed\s*|engaged\s*to\s*perform)\s*an\s*integrated\s*audit))|In\s*our\s*opinion,\s*the\s*(consolidated|accompanying)))';	
my $startstringhtm='(((We\s*(have|were)\s*(audited\s*the\s*(Statement\s*of\s*Financial\s*Condition|consolidated|accompanying|combined|balance\s*sheets)|(completed\s*|engaged\s*to\s*perform)\s*an\s*integrated\s*audit))|In\s*our\s*opinion,\s*the\s*(consolidated|accompanying)))';	
#Specify the end of the text you are looking for.
my $endstring='((^\s*)/s/|^\s*(Date:\s*)?(\d{1,2}\s*)?((January|February|March|April|May|June|July|August|September|October|November|December))\s*(\d{1,2},)?\s*\d{4}(\s*$|,\s{0,3}except|\s*/s|\s*s/|\d{1,2}))';
my $endstringhtm='((>|^\s*)(/s/)?\s*(Date:\s*)?(\d{1,2}\s*)?(January|February|March|April|May|June|July|August|September|October|November|December))\s*(&\w+?;\s*)?(\d{1,2},)?\s*\d{4}(\s*$|\s*[,\(]\s{0,3}except|\s*with\s*respect\s*to\s*our\s*opinion|<\/P>|<BR>|\s{0,1}\<\/FONT\>|\d{1,2})';


#Specify the beginning of text you are looking for. You my need a different one for HTML versus text filings
#my $startstring='((^\s*?)((?:We\s*(have|were)\s*(?:audited\s*the\s*(?:Statement\s*of\s*Financial\s*Condition|consolidated|accompanying|combined|balance\s*sheets)|(?:completed\s*|engaged\s*to\s*perform)\s*an\s*integrated\s*audit))|In\s*our\s*opinion,\s*the\s*(?:consolidated|accompanying)))';	
#my $startstringhtm='(?:(?:(?:We\s*(?:have|were)\s*(?:audited\s*the\s*(?:Statement\s*of\s*Financial\s*Condition|consolidated|accompanying|combined|balance\s*sheets)|(?:completed\s*|engaged\s*to\s*perform)\s*an\s*integrated\s*audit))|In\s*our\s*opinion,\s*the\s*(?:consolidated|accompanying)))';	
##Specify the end of the text you are looking for.
#my $endstring='(?:(?:^\s*)/s/|^\s*(?:Date:\s*)?(?:\d{1,2}\s*)?(?:(?:January|February|March|April|May|June|July|August|September|October|November|December))\s*(?:\d{1,2},)?\s*\d{4}(?:\s*$|,\s{0,3}except|\s*/s|\s*s/|\d{1,2}))';
#my $endstringhtm='(?:(?:>|^\s*)(/s/)?\s*(?:Date:\s*)?(\d{1,2}\s*)?(?:January|February|March|April|May|June|July|August|September|October|November|December))\s*(?:&\w+?;\s*)?(?:\d{1,2},)?\s*\d{4}(?:\s*$|\s*[,\(]\s{0,3}except|\s*with\s*respect\s*to\s*our\s*opinion|<\/P>|<BR>|\s{0,1}\<\/FONT\>|\d{1,2})';

#Specify the directory containing the files that you want to read
my $direct="c:\\PERLCOURSE\\10k\\2007";

#If Windows "\\", if Mac "/";
my $slash='\\';
#The following two steps open the directory containing the files you plan to read
#and then stores the name of each file in an array called @New1.
opendir(DIR1,"$direct")||die "Can't open directory";
my @New1=readdir(DIR1);

#We will now loop through each file.  THe file names
#have been stored in the array called @New1;

foreach $file(@New1)
{
#This prevents me from reading the first two entries in a directory . and ..;

if ($file=~/^\./){next;}
#Initialize the variable names.
my $cik=-99;
my $report_date=-99;
my $file_date=-99;
my $name="";
my $sic=-99;
my $HTML=0;
my $Audit_Opinion="Not Found";
my $Going_Concern=0;
my $ao="Not Found";
my $tree="Empty";
my $data="";
#Open the file and put the file in variable called $data
#$data will contain the entire filing
{
# this step removes the default end of line character (\n)
# so the the entire file can be read in at once.
local $/;
open (SLURP, "$direct$slash"."$file") or die "can't open $file: $!"; 
#read the contents into data
$data = <SLURP>; 
}
#close the filehandle called SLURP
close SLURP or die "cannot close $file: $!";
#The following steps obtain basic data from the filings
  if ($data=~m/<HTML>/i){$HTML=1;}
  if($data=~m/^\s*CENTRAL\s*INDEX\s*KEY:\s*(\d*)/m){$cik=$1;}
  if($data=~m/^\s*CONFORMED\s*PERIOD\s*OF\s*REPORT:\s*(\d*)/m){$report_date=$1;}
  if($data=~m/^\s*FILED\s*AS\s*OF\s*DATE:\s*(\d*)/m){$file_date=$1;}
  if($data=~m/^\s*COMPANY\s*CONFORMED\s*NAME:\s*(.*$)/m){$name=$1;}
  if($data=~m/^\s*STANDARD\s*INDUSTRIAL\s*CLASSIFICATION:.*?\[(\d{4})/m){$sic=$1;}
 
 #The following steps extract the audit opinion (or whatever section of text you want) 
 #The first if statement determines whether the filing is in HTML format or plain text.
 
  if($HTML==0){
                #These steps are executed if it is a plain text document
                #We use the regular expressions $startstring and $endstring
                #because they are specifically for nonhtml filings.
                #The first if statement below finds the start of the audit opinion
                # The start of the line plus the following 200 lines (or less) is
                #extracted and retained in the variable $data ($data now only contains
                #200 lines of data beginning with the startstring)
                #A quick note on part of this regular expression -(?:[^\n]*\n){50,200}
                #(?: This part just tells perl not to save the information to its own variable (e.g., $2)
                #Next we we tell PERL to give the next 50 to 200 lines (it will get as many as it can
                #so this is usually going to be 200).
                #[^\n]* means any character that is not a newline character.
                #\n is the newline character.
                #{50,200} just means 50 to 200 occurrences of the string.
                if($data=~m/($startstring(?:[^\n]*\n){50,200})/ismo)
                {
                $data=$1;
                #Now we look for the end of the opinion.  If it is found,
                #we store everything in data up to the endstring plus 10 lines.
                #The extra 10 lines is just to be sure we pick up any additional
                #notes, etc. If the end string is not found, the entire
                #data variable is included in the data extraction.  This will
                #include the startsring plus the next 200 lines.
                if($data=~m/(.*?$endstring(?:[^\n]*\n){1,10})/ismo){$Audit_Opinion=$1;}
                else{$Audit_Opinion=$data;}
                }
               }
        else{
                #The same steps are repeated for HTML documents
                #but we just use the html start and endstrings.
               if($data=~m/($startstringhtm(?:[^\n]*\n){50,200})/ismo)
               {
                  $data=$1;
                  if($data=~m/(.*?$endstringhtm(?:[^\n]*\n){1,10})/ismo){$ao=$1;}
                    else{$ao=$data;}
                    #the following steps strip out any HTML tags, etc.
                  $tree=HTML::TreeBuilder->new->parse($ao);
                  $formatter=HTML::FormatText->new(leftmargin=> 0, rightmargin=>60);
                 $Audit_Opinion=$formatter->format($tree);
               }
             }
#check to see if the opinion is a GC       
if ($Audit_Opinion=~/going\s*concern/smi)
        {$Going_Concern=1;}
	else {$Going_Concern=0;}
#print what we find.
print "Line number: file: $file\nHTML: $HTML\nCIK: $cik\nReport Date: $report_date\nFile Date: $file_date\nName: $name\nSIC: $sic\n$Audit_Opinion\n","*" x 40, "\n" ;
}

$endTime = new Benchmark;
$runTime = timediff($endTime, $startTime);
print ("Processing files took ", timestr($runTime));
#checks to see what files on the current index listing are not in the directory
#This extracts the chunk of code you are looking for.
