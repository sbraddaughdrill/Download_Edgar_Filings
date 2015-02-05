*=====================================================================;
*PROGRAM DETAILS;
*=====================================================================;
*Program: 	Web_Crawler.sas;
*Version: 	1.0;
*Author:    S. Brad Daughdrill;
*Date:		02.29.2012;
*Purpose:	FI 614 - Dr. Doug Cook - Class Paper;
*=====================================================================;
*MACROS USED;
*=====================================================================;
*-------------------------------Name----------------------------------;
* %DeleteMacros;
* %IncludeMacros (projfolder=,researchfolder=);
* %HeaderOptions;
* %GlobalMacroVars;
* %Import (directory=, inputlibname=,outputlibname=,droppedvariables=);
* %VarDescrip (directory=,inputlibraryname=,inputdataset=, 
			   outputdataset=, outputfilename=);
* %DataSetList (inputlibraryname=, outputdataset=);
* %DescripStat (directory=,inputlibraryname=,outputdataset=);
* %VariableList (inputlibraryname=,inputdataset=,outputdataset=,
				 outputdatasetsorted=,droppedvariables=);
* %VariableOBSCount (inputdataset=,variables=,totalobs=,totalvars=);
*=====================================================================;
%include "C:\Users\bdaughdr\Dropbox\Research\SAS\Macros\Brad\DeleteMacros.sas"; *Office;
*%include "\\tsclient\C\Users\bdaughdr\Dropbox\Research\SAS\Macros\Brad\DeleteMacros.sas"; *CoralSea from Office;
*%include "\\tsclient\C\Users\S. Brad Daughdrill\Documents\My Dropbox\Research\SAS\Macros\Brad\DeleteMacros.sas";  *CoralSea from Home;
*=====================================================================;
*Delete Macro Variables;
*=====================================================================;
%DeleteMacros;
*=====================================================================;
*Create Macro Directory;
*=====================================================================;
%global fullmacrodirectory;
%let fullmacrodirectory=C:\Users\bdaughdr\Dropbox\Research\SAS\Macros; *Office;
*%let fullmacrodirectory=\\tsclient\C\Users\bdaughdr\Dropbox\Research\SAS\Macros; *CoralSea from Office;
*%let fullmacrodirectory=\\tsclient\C\Users\S. Brad Daughdrill\Documents\My Dropbox\Research\SAS\Macros;  *CoralSea from Home;
*=====================================================================;
*Create Local Directories;
*=====================================================================;
%global projectrootdirectory;
%let projectrootdirectory=H:\Research\Web_Crawler;
*=====================================================================;
*Macro includes;
*=====================================================================;
%include "&fullmacrodirectory.\IncludeMacros.sas";
%IncludeMacros (projfolder=&projectrootdirectory.,researchfolder=&fullmacrodirectory.);
*=====================================================================;
*Sets initial options (clears output window and log, sets linesize);
*=====================================================================;
%HeaderOptions;
*=====================================================================;
*Global Macro Variables;
*=====================================================================;
%GlobalMacroVars;
*=====================================================================;
*Creates Libraries;
*=====================================================================;
%let rawdatalibrary=rawdata;
libname &rawdatalibrary. "&projectrootdirectory.\Data\Original";
%let finaldatalibrary=gooddata;
libname &finaldatalibrary. "&projectrootdirectory.\Data\Final";
%let testdatalibrary=testdata;
libname &testdatalibrary. "&projectrootdirectory.\Data\Test";
*=====================================================================;
*Sort and Merge Trace and CUSIP_All data;
*=====================================================================;

data work.links_to_crawl;
   length url $256;
   input url $;
   datalines;
http://bama.ua.edu/~daugh016/MIS320/index.htm

;
run;
 
 
%macro crawler();
   %let html_num = 1;
 
   data work.links_crawled;
      length url $256;
   run;
 
%next_crawl:
   /* pop the next url off */
   %let next_url = ;
 
   data work.links_to_crawl;
      set work.links_to_crawl;
      if _n_ eq 1 then call symput("next_url", url);
      else output;
   run;
 
   %let next_url = %trim(%left(&next_url));
 
   %if "&next_url" ne "" %then %do;
 
      %put crawling &next_url ... ;
 
      /* crawl the url */
      filename _nexturl url "&next_url";
 
      /* put the file we crawled here */
      filename htmlfile "&projectrootdirectory.\Data\Test\file%trim(&html_num).html";
 
      /* find more urls */
      data work._urls(keep=url);
         length url $256 ;
         file htmlfile;
         infile _nexturl length=len;
         input text $varying2000. len;
 
         put text;
 
         start = 1;
         stop = length(text);
 
         if _n_ = 1 then do;
            retain patternID;
            pattern = '/href="([^"]+)"/i';
            patternID = prxparse(pattern);
         end;
 
         /* Use PRXNEXT to find the first instance of the pattern, */
         /* then use DO WHILE to find all further instances.       */
         /* PRXNEXT changes the start parameter so that searching  */
         /* begins again after the last match.                     */
         call prxnext(patternID, start, stop, text, position, length);
         do while (position ^= 0);
            url = substr(text, position+6, length-7);
            * put url=;
            output;
            call prxnext(patternID, start, stop, text, position, length);
         end;
      run;
 
      /* add the current link to the list of urls we have already crawled */
      data work._old_link;
         url = "&next_url";
      run;
      proc append base=work.links_crawled data=work._old_link;
      run;
 
      /* only add urls that we haven't already crawled or that aren't queued up to be crawled */
      proc sql noprint;
         create table work._append as
            select url 
            from work._urls
            where url not in (select url from work.links_crawled)
                  and url not in (select url from work.links_to_crawl);
      quit;
 
      /* only add urls that are absolute (http://...) */
      data work._append;
         set work._append;
         absolute_url = substrn(url, 1, 7);
         put absolute_url=;
         if absolute_url eq "http://" ; 
         drop absolute_url;
      run;
 
      /* add new links */
      proc append base=work.links_to_crawl data=work._append force;
      run;
 
      /* increment our file number */
      %let html_num = %eval(&html_num + 1);
 
      /* loop */
      %goto next_crawl;
   %end;
 
%mend crawler;
 
%crawler();
