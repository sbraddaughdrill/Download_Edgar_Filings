#!/usr/bin/perl -w
#use strict;
#This file downloads the index files from Edgar.  Edgar has an index
#file for each quarter and year so you need to grab each one.
#This program was written by Andy Leone, May 15 2007 and updated  July 25, 2008.
#You are free to use this program for your own use.  My only request is
#that you make an acknowledgement in any research manuscripts that
#benefit from the program.

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Net::FTP;

#Specifiy the following parameters:
#First year you want index files for:
my $startyear=2009;
#Last year you want index files for:
my $endyear=2009;
#First qtr you want index files for (usually 1):
my $startqtr=1;
#Last year you want index files for (usually 4):
my $endqtr=1;
#This is the directory that the index files will be downloaded to. 
my $direct="/Volumes/EDGAR1/Edgar/full-index";


#if using windows, set to "\\" - if mac (or unix), set to "/";
#generally, nothing below this line needs to be changed.

my $slash='/';
#create directory if it does not already exist
unless(-d "$direct"){
    mkdir("$direct") or die;}
#get index files;
#FTP signin-
     $ftp = Net::FTP->new("ftp.sec.gov", Debug => 0)
     or die "Cannot connect to some.host.name: $@";

#This provides your user name and password.

    $ftp->login("anonymous",'-anonymous@')
    or die "Cannot login ", $ftp->message;

#Get files loop- The program will loop through each year specified  specified.
#Note that the counter (yr) starts with a value equal to start year
# and increments by 1 each time through.  The loop terminates
#after the counter exceeds $endyear.
for($yr=$startyear;$yr<=$endyear;$yr++)

{
   if($yr<$endyear){$eqtr=4}else{$eqtr=$endqtr}
   for($QTR=$startqtr;$QTR<=$eqtr;$QTR++)
   {

        #filetoget is the name of the file we are going to get from edgar. Edgar
        #stores each file in its own year and qtr directory and
        #we change the directory by using the counter and qtr variables.

        $filetoget="/edgar/full-index/$yr/QTR$QTR/company.zip";
        #$fonly is the name (and location) we are giving the file to be downloaded.
        #we have to give it a unique year and quarter name so each file is not
        #overwritten by the other.
        $fonly="$direct$slash"."company$QTR$yr.zip";
        #fidx is the name of the file we are going to give to the file we unzip.
        $fidx="$direct$slash"."company$QTR$yr.idx";
        #This tells the ftp module that we are going to ftp a binary file.
        $ftp->binary();
        #THis is the actual excution of the get command (get file).
        $ftp->get("$filetoget", "$fonly")

      or  die "cannot connect: $@" ; #$QTR++, ftpsignin(),next;
      #Here we tell the zip module what file we are going to unzip.

     $zip = Archive::Zip->new($fonly);

    die 'read error' unless $zip->read( $fonly ) == AZ_OK;

   #here we read the file we are unzipping.
  my $member1=$zip->read( $fonly );
   #here we tell zip the exact member of the zip file that we want (there is only one in our case).
 my $member2=$zip->extractMember( 'company.idx' , $fidx );

   }
}
    $ftp->quit;





