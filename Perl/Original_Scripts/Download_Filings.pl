#!/usr/bin/perl -w

#use strict;



use Tie::File;
use Fcntl;
#This program reads the company.idx files and then 
#files are downloaded to separate year directories

#This program was written by Andy Leone, May 15 2007 and updated  July 25, 2008.
#You are free to use this program for your own use.  My only request is
#that you make an acknowledgement in any research manuscripts that
#benefit from the program.

#NOTE: YOU SHOULD RUN THIS PROGRAM ONE YEAR AT A TIME
#First year you want downloaded files for for:
my $startyear=2008;
#Last year you want files for:

my $endyear=2008;
#First qtr you want  files for (usually 1):
my $startqtr=3;

#Last year you want files for (usually 4):

my $endqtr=4;
#The directory you want your index files to be stored in.
my $inddirect="/Volumes/EDGAR1/Edgar/full-index";
#The directory you  are going to download filings to
my $direct="/Volumes/EDGAR1/Edgar/Edgar2/8k";
#The file that will contain the filings you want to download.
my $outfile="/Volumes/EDGAR1/Edgar/getfiles.txt";

#Specifiy, in regular expression format, the filing
#you are looking for.  Following is the for 10-k.
# In this case, I only want to keep 10-ks.
# I put a ^ at the beginning because I want the
#form type to start with 10, this gets rid of NT late filings.
#I also want to exclude amended filings so I specify that 10-k
#should not be followed by / (e.g., 10-K/A).
#my $formget='(10-?K(SB)?|20-?F)';
my $formget='(8-k)';
#if using windows, set to "\\" - if mac (or unix), set to "/";
my $slash='/';
#####################

#generally, nothing below this line needs to be changed. However, you will

#want to change the regular expression specifying the form_type to keep.



#loop through all the index years you specfied

for($yr=$startyear;$yr<=$endyear;$yr++)

{
#loop through all the index quarters you specified
if($yr<$endyear){$eqtr=4}else{$eqtr=$endqtr}
for($qtr=$startqtr;$qtr<=$eqtr;$qtr++)

{
#Open the index file
open(INPUT, "$inddirect$slash"."company$qtr$yr.idx") || die "file for 2006 1: $!";
#Open the file you want to write to.  The first time through
#the file is opened to "replace" the existing file.
#After that, it is opened to append ">>".

if ($yr==$startyear && $qtr==$startqtr)
{$outfiler=">$outfile";}
else{$outfiler=">>$outfile";}
open(OUTPUT, "$outfiler") || die "file for 2006 1: $!";
$count=1;
#The following while statement is like others we have seen before
#the only difference is the addition of $line=<INPUT>.
#all this does is each time a line is read, it is stored in the
#variable called $lien.

while ($line=<INPUT>)

    {

#ignore the first 10 lines because they only contain header information

if ($.<11) {next};

#the index file is a standard format so I can just use the substr function
#to specify the part of the line I want to assign to each variable
#have a look one of the files to see how it looks.
#$company_name=substr($line,0,60);
$form_type=substr($line,62,12);
#$cik=substr($line,74,10);

$file_date=substr($line,86,10);
#Note that for file date, we need to get rid of 
#the - with the following regular expression.
#month-day-year and some years there is not.
#This regular expression 
$file_date=~s/\-//g;
$fullfilename=trim(substr($line,98,43));
# In this case, I only want to keep 10-ks.
# I put a ^ at the beginning because I want the
#form type to start with 10, this gets rid of NT late filings.
#I also want to exclude amended filings so I specify that 10-k
#should not be followed by / (e.g., 10-K/A).
if ($form_type=~/$formget/i)
{
    print OUTPUT "$fullfilename\n" ;
    $count++;
}
#if ($count>10){last;}
#end of the while loop <INPUT>
   }

close(INPUT);
close(OUTPUT);
# check to see if directory exists.  If not, create it.
unless(-d "$direct$slash$yr"){
    mkdir("$direct$slash$yr") or die;
}
#Open the directory and get put the names of all files into the array @old
opendir(DIR,"$direct$slash$yr")||die "Can't open directory";
@Old=readdir(DIR);
#The tie statement assigns the file containing the
#files you want to download to the array @New1.
tie(@New1,Tie::File,"$outfile", mode=> O_RDWR)
or die "Cannot tie file BOO: $!n";
#checks to see what files on the current index listing are not in the directory
#defines a hash called seen.
%seen=();
#defines an array called @aonly.
@aonly=();
#build lookup table.  This step is building a lookup table(hash).
#each filename (from OLD) has a value of 1 assigned to it.
foreach $item(@Old){$seen{$item}=1}
#for each item in the New1 array, which we got from the txt file
#containing all the files we want to download, add
#it to the array, @aonly, as long is it is not already
#in the current directory.  We do this so we don't download
#a file we have already downloaded.
foreach $item(@New1){
         $item=~/(edgar\/data\/.*\/)(.*\.txt)/;
    unless($seen{$2}){
        push(@aonly,$item);

    }

}

#downloads all the files in the @oanly array which are the files not in the directory
ftpsignin();

foreach $filetoget(@aonly)

{
#    $filetoget=trim($filetoget);
    $fullfile="/$filetoget";
    $fonly=$filetoget;
    #Don't forget to put your directory in here.
    $fonly=~s/.*\/(.*)/$direct$slash$yr$slash$1/;
    $ftp->get("$fullfile", "$fonly")
    or  warn "can't get file",ftpsignin(),next; # "cannot get file",$ftp->message, next;

}
    $ftp->quit;
#end of qtr loop
}
#end of year loop
}

sub ftpsignin {
    use Net::FTP;
     $ftp = Net::FTP->new("ftp.sec.gov", Debug => 0)
     or die "Cannot connect to some.host.name: $@";
     $ftp->login("anonymous",'-anonymous@')
     or next; #die "Cannot login ", $ftp->message;

}   

sub trim {
    my $new_phrase;
    my $phrase = shift(@_);
    $phrase =~ s/^\s+//;
    $phrase =~ s/\s+$//;
    $new_phrase = "$phrase";
    return "$new_phrase";
     }                

