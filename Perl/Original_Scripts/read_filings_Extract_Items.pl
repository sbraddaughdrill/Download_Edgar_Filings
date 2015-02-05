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

#This program was written by Andy Leone, December 20, 2007.

#This program is written to obtain "Items" in the 10-K.  The specific case here is Item 9 (or item 8)  Changes in and Disagreements with Accountants on Accounting and Financial Disclosure.
#You should be able to obtain other items but changing the item numbers and the descriptions in the regular expressions.

#Specify the beginning of text you are looking for. You my need a different one for HTML versus text filings
#note a strange case I</a>tem 9


my $startstring='((^\s*?)Item\s+[89]A[\.\-]?\s+Controls[^\d]*?procedure[^\d]*?\n)';
my $startstringhtm='((>\s?|^\s*?)Item(&.{1,5};\s*)*\s*[89]A\.?\s*(<[^<]*>\s*)*(&.{1,5};\s*)*\.?(<[^<]*>\s*)*\s*Control[^\d]*?Procedure[^\d]*?(\n|<))';
#Specify keywords/phrases you expect to find within the item (make sure the words phrases are not also in the start or end string)
my $keywords='(none|not\s*applicable|no\s*change|January|February|March|April|May|June|July|August|September|October|November|December)';
#Specify the end of the text you are looking for.
my $endstring='((^\s*?)Item\s+(8A|9|9A|10)[\.\-]?[^\d]*?\n)';
my $endstringhtm='((>\s*|^\s*)Item(&.{1,5};\s*)*\s*(8A|9A?|10)[\.\-]?\s*(&.{1,5};\s*)*[^\d]*?(\n|<))';
#Specify the directory containing the files that you want to read
my $direct="c:\\perlclass\\10k\\2007";

#if windows '\\', if mac '/';
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
my $ao="Not Found";
my $tree="Empty";
my $data="";
my @finds=();
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
                #The first if statement below finds all cases where
                #a match occurs into the array called @finds.  
                @finds=$data=~m/($startstring.*?$endstring)/ismog;
                   #This statement makes sure that any elements in the
                   #array contain words that are expected within the Item.
                      @finds=grep(/$keywords/ismog,@finds);
                  #The variable Audit_Opinion is then given
                # the first element in the array called finds.
                 $Audit_Opinion=$finds[0];
#                if($data=~m/($startstring.*?$keywords.*?$endstring)/ismo)
 #               {$Audit_Opinion=$1;}
               }
        else{
                #The same steps are repeated for HTML documents
                #but  with a few subtle differences.  First, we use different
                #start and end strings. 
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
#print what we find.
print "Elements: $#finds\nLine number: file: $file\nHTML: $HTML\nCIK: $cik\nReport Date: $report_date\nFile Date: $file_date\nName: $name\nSIC: $sic\n$Audit_Opinion\n","*" x 40, "\n" ;
}

$endTime = new Benchmark;
$runTime = timediff($endTime, $startTime);
print ("Processing files took ", timestr($runTime));
#checks to see what files on the current index listing are not in the directory
#This extracts the chunk of code you are looking for.
