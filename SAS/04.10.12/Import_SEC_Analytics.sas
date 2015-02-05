*=====================================================================;
*PROGRAM DETAILS;
*=====================================================================;
*Program: 	Import_SEC_Analytics.sas;
*Version: 	1.0;
*Author:    S. Brad Daughdrill;
*Date:		02.29.2012;
*Purpose:	Import data from WRDS SEC Analytics Suite;
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
*%symdel projectrootdirectory;
%global projectrootdirectory;
%let projectrootdirectory=H:\Research\Web_Crawler;
*=====================================================================;
*Macro includes;
*=====================================================================;
%include "&fullmacrodirectory.\IncludeMacros.sas";
%IncludeMacros (projfolder=&projectrootdirectory.,researchfolder=&fullmacrodirectory.);
*=====================================================================;
*Sets initial options (clears output window and log, sets linesize,etc.);
*=====================================================================;
title;
footnote;

options ls=102;
options ps=80;
options label;
options nocenter;

/*
options macrogen;  *macro debugging;
options mlogic;    *macro debugging;
options mprint;    *echo macro text;
options notes;     *time-used notes;
*/


options symbolgen; *macro debugging;
options source;  *echo statements;
options source2; *echo includes;
options mfile;
options spool;


options nomacrogen;  *no macro debugging;
options nomlogic;    *no macro debugging;
options nomprint;    *no echo macro text;
options nosymbolgen; *no macro debugging;
options nonotes;     *no time-used notes;

/*
options nosource;    *no echo statements;
options nosource2;   *no echo includes;
options nomfile;
options nospool;
*/

DM 'clear output';    	
DM 'clear log';
DM 'GRAPH; CANCEL;'; 

proc greplay igout=work.gseg nofs;
	delete _all_;
	run;
quit;
proc datasets lib=work nolist; delete vars ; quit; run; 
*=====================================================================;
*Define log and output path;
*=====================================================================;
Proc printto log="&projectrootdirectory.\mylog.log";
run;
proc printto print="&projectrootdirectory.\myoutput.lst";
run;
Proc printto log=log;
run;
Proc printto print=print;
run;
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
%let emdatalibrary=emdata;
libname &emdatalibrary. "C:\Documents and Settings\bdaughdr\My Documents\My SAS Files\9.2";
*=====================================================================;
*Prompt for WRDS login password;
*=====================================================================;
%let pwwrds=BigBrad12;
/*%window info
  #5 @5 'Please enter WRDS password:'
  #5 @33 pwwrds 32 attr=underline display=yes;
%display info;*/
*=====================================================================;
*Encode login password;
*=====================================================================;
%let pwfilename=pwfile;
filename &pwfilename. "&projectrootdirectory.\Data\Original\&pwfilename..txt";
proc pwencode in="&pwwrds." out=&pwfilename.;
run;
data _null_;
	infile &pwfilename. obs=1 length=l; 
	input @;
	input @1 line $varying1024. l; 
	call symput('dbpass',substr(line,1,l)); 
run;
*=====================================================================;
*Delete password file;
*=====================================================================;
data _null_;
	rc=filename("&pwfilename.","&projectrootdirectory.\Data\Original\&pwfilename..txt");
    if rc = 0 and fexist("&pwfilename.") then do;
       rc=fdelete("&pwfilename.");
	end;
    rc=filename("&pwfilename.");
run;
*=====================================================================;
*Use this step if using SAS/Connect to WRDS (do step idependently of others);
*=====================================================================;
*%let wrds = wrds-cloud.wharton.upenn.edu 4016;
%let wrds = wrds.wharton.upenn.edu 4016; 
options comamid=TCP remote=WRDS;  
signon username=bdaughdr password="&dbpass";
*=====================================================================;
*Reassign libnames so that datasets can be viewed in SAS Explorer;
*=====================================================================;
*rsubmit;
*%include 'wrdslib_remote.sas';
*endrsubmit;
libname myhome remote  '.' server=WRDS;
libname mysec remote  '/wrds/sec/sasdata' server=WRDS;

*Home Library Name to save the final SAS dataset;
rsubmit;
libname myh '.'; 
libname wrdssec '/wrds/sec/sasdata';

*x 'mkdir /sastemp5/mydata';
*libname mylib '/sastemp5/mydata';

endrsubmit;
*=====================================================================;
*Create macro variables for analysis;
*=====================================================================;
%let columntitle=_;
%let columnyear=fyear;
%let inputdataset=textparse_match_final;
%let outputdataset=Final_Stats;
%let paragraphcol=Match_Text;
*********************************************************************************;
*STEP ONE: Extract data;
*********************************************************************************;
/*
rsubmit;
%let my_names_vars = CIK CONAME GVKEY CUSIPH TICKERH CUSIP_FULL CUSIP;	
data my_names(keep = &my_names_vars.);	
	set wrdssec._names_;
run;
proc download data=my_names out=my_names; run;
endrsubmit;

rsubmit;
data my_qvards;	
	set wrdssec._qvards_;
run;
proc download data=my_qvards out=my_qvards; run;
endrsubmit;

rsubmit;
%let my_dforms_yrstrt = 2008;			
%let my_dforms_yrend = 2008;	
%let my_dforms_vars = CIK FDATE SECDATE FORM CONAME FNAME;
data my_dforms(keep = &my_dforms_vars.);	
	set wrdssec.dforms;
	where year(fdate) between (&my_dforms_yrstrt.-1) and (&my_dforms_yrend.+1); 
run;
proc download data=my_dforms out=my_dforms; run;
endrsubmit;

rsubmit;
%let my_fforms_yrstrt = 2008;			
%let my_fforms_yrend = 2008;
%let my_fforms_vars = CIK FDATE SECDATE FORM CONAME FNAME;
data my_fforms(keep = &my_fforms_vars.);	
	set wrdssec.fforms;
	where year(fdate) between (&my_fforms_yrstrt.-1) and (&my_fforms_yrend.+1); 
run;
proc download data=my_fforms out=my_fforms; run;
endrsubmit;

rsubmit;
%let my_forms_yrstrt = 2008;			
%let my_forms_yrend = 2008;
%let my_forms_vars = GVKEY CIK FDATE FINDEXDATE LINDEXDATE FORM CONAME FNAME INAME SOURCE;
data my_forms(keep = &my_forms_vars.);	
	set wrdssec.forms;
	where year(fdate) between (&my_forms_yrstrt.-1) and (&my_forms_yrend.+1); 
run;
proc download data=my_forms out=my_forms; run;
endrsubmit;

rsubmit;
%let my_items8k_yrstrt = 2008;			
%let my_items8k_yrend = 2008;
%let my_items8k_vars = GVKEY CIK FDATE FORM CONAME FNAME FSIZE RDATE SECADATE SECATIME NITEM ITEM NITEMNO ITEMNO;
data my_items8k(keep = &my_items8k_vars.);	
	set wrdssec.items8k;
	where year(fdate) between (&my_items8k_yrstrt.-1) and (&my_items8k_yrend.+1); 
run;
proc download data=my_items8k out=my_items8k; run;
endrsubmit;

rsubmit;
%let my_items8k2_yrstrt = 2008;			
%let my_items8k2_yrend = 2008;
%let my_items8k2_vars = GVKEY CIK FDATE FORM CONAME FNAME FSIZE RDATE SECADATE SECATIME NITEM ITEM NITEMNO;
data my_items8k2(keep = &my_items8k2_vars.);	
	set wrdssec.items8k2;
	where year(fdate) between (&my_items8k2_yrstrt.-1) and (&my_items8k2_yrend.+1); 
run;
proc download data=my_items8k2 out=my_items8k2; run;
endrsubmit;

rsubmit;
%let my_items8k_list_vars = NITEM ITEM;
data my_items8k_list(keep = &my_items8k_list_vars.);	
	set wrdssec.items8k_list;
run;
proc download data=my_items8k_list out=my_items8k_list; run;
endrsubmit;

rsubmit;
%let my_wciklink_cusip_vars = CIK CONAME CUSIP_FULL CUSIP CIKDATE1 CIKDATE2 TMATCH ISSUER ISSUE ISSUE_CHECK VALIDATED;
data my_wciklink_cusip(keep = &my_wciklink_cusip_vars.);	
	set wrdssec.wciklink_cusip;
run;
proc download data=my_wciklink_cusip out=my_wciklink_cusip; run;
endrsubmit;

rsubmit;
%let my_wciklink_gvkey_vars = GVKEY CONM DATADATE1 DATADATE2 CIK SOURCE CONAME FNDATE LNDATE N10K N10K_NT N10K_A N10Q N10Q_NT N10Q_A NDEF N8K NTOT FLAG;
data my_wciklink_gvkey(keep = &my_wciklink_gvkey_vars.);	
	set wrdssec.wciklink_gvkey;
run;
proc download data=my_wciklink_gvkey out=my_wciklink_gvkey; run;
endrsubmit;

rsubmit;
%let my_wciklink_names_vars = CIK CONAME FNDATE LNDATE N10K N10K_NT N10K_A N10Q N10Q_NT N10Q_A NDEF N8K NLET N13D N13G N13F NTOT NTOT_NT NTOT_A HEADER GVKEY CUSIPH TICKERH;
data my_wciklink_names(keep = &my_wciklink_names_vars.);	
	set wrdssec.wciklink_names;
run;
proc download data=my_wciklink_names out=my_wciklink_names; run;
endrsubmit;

rsubmit;
%let my_wforms_yrstrt = 2008;			
%let my_wforms_yrend = 2008;
%let my_wforms_vars = GVKEY CIK FDATE FINDEXDATE LINDEXDATE FORM CONAME FNAME INAME SOURCE FSIZE ISIZE;
data my_wforms(keep = &my_wforms_vars.);	
	set wrdssec.wforms;
	where year(fdate) between (&my_wforms_yrstrt.-1) and (&my_wforms_yrend.+1); 
run;
proc download data=my_wforms out=my_wforms; run;
endrsubmit;

rsubmit;
%let my_wforms2_yrstrt = 2008;			
%let my_wforms2_yrend = 2008;
%let my_wforms2_vars = GVKEY CIK FDATE FINDEXDATE LINDEXDATE FORM CONAME FNAME INAME SOURCE FSIZE ISIZE RDATE SECADATE SECATIME SIC STATE_INC STATE_HDQ ZIP_HDQ FYE;
data my_wforms2(keep = &my_wforms2_vars.);	
	set wrdssec.wforms2;
	where year(fdate) between (&my_wforms2_yrstrt.-1) and (&my_wforms2_yrend.+1); 
run;
proc download data=my_wforms2 out=my_wforms2; run;
endrsubmit;




*NOTE:  Earliest date in Edgar is 1994;
rsubmit;
%let my_exhibits_yrstrt = 1994;			
%let my_exhibits_yrend = 2010;
%let my_exhibits_vars = GVKEY CIK FDATE FORM CONAME FNAME FSIZE RDATE SECADATE SECATIME SEQUENCE TYPE DESCRIPTION FILENAME;
data my_exhibits(keep = &my_exhibits_vars.);	
	set wrdssec.exhibits;
	*where year(fdate) between (&my_exhibits_yrstrt.-1) and (&my_exhibits_yrend.+1); 
	where year(fdate) between (&my_exhibits_yrstrt.) and (&my_exhibits_yrend.); 
run;
proc download data=my_exhibits out=my_exhibits; run;
endrsubmit;

*Find and remove filings that aren't 10-k's;
rsubmit;
data my_exhibits_not_10k;	
	set my_exhibits;
	where form not like '%10%K%';
run;
proc download data=my_exhibits_not_10k out=my_exhibits_not_10k; run;
data my_exhibits_10k;	
	set my_exhibits;
	where form like '%10%K%';
run;
proc download data=my_exhibits_10k out=my_exhibits_10k; run;
endrsubmit;

*Find and remove exhibits, graphics, etc;
rsubmit;
data my_exhibits_10k_extra;	
	set my_exhibits_10k;
	where type not like '%10%K%';
run;
proc download data=my_exhibits_10k_extra out=my_exhibits_10k_extra; run;
data my_exhibits_10k_no_extra;	
	set my_exhibits_10k;
	where type like '%10%K%';
run;
proc download data=my_exhibits_10k_no_extra out=my_exhibits_10k_no_extra; run;
endrsubmit;

*Find and remove the NT 10-K's from form;
rsubmit;
data my_exhibits_nt10k;	
	set my_exhibits_10k_no_extra;
	where form not like '10%K%';
run;
proc download data=my_exhibits_nt10k out=my_exhibits_nt10k; run;
data my_exhibits_10k_no_nt10k;	
	set my_exhibits_10k_no_extra;
	where form like '10%K%';
run;
proc download data=my_exhibits_10k_no_nt10k out=my_exhibits_10k_no_nt10k; run;
endrsubmit;

*Find and remove the NT 10-K's from type;
rsubmit;
data my_exhibits_nt10k2;	
	set my_exhibits_10k_no_nt10k;
	where type not like '10%K%';
run;
proc download data=my_exhibits_nt10k2 out=my_exhibits_nt10k2; run;
data my_exhibits_10k_no_nt10k2;	
	set my_exhibits_10k_no_nt10k;
	where type like '10%K%';
run;
proc download data=my_exhibits_10k_no_nt10k2 out=my_exhibits_10k_no_nt10k2; run;
endrsubmit;

*Find and remove the /A's from form;
rsubmit;
data my_exhibits_10k_a;	
	set my_exhibits_10k_no_nt10k2;
	where form like '%A%';
run;
proc download data=my_exhibits_10k_a out=my_exhibits_10k_a; run;
data my_exhibits_10k_no_a;	
	set my_exhibits_10k_no_nt10k2;
	where form not like '%A%';
run;
proc download data=my_exhibits_10k_no_a out=my_exhibits_10k_no_a; run;
endrsubmit;

*Find and remove the /A's from type;
rsubmit;
data my_exhibits_10k_a2;	
	set my_exhibits_10k_no_a;
	where type like '%A%';
run;
proc download data=my_exhibits_10k_a2 out=my_exhibits_10k_a2; run;
data my_exhibits_10k_no_a2;	
	set my_exhibits_10k_no_a;
	where type not like '%A%';
run;
proc download data=my_exhibits_10k_no_a2 out=my_exhibits_10k_no_a2; run;
endrsubmit;

*Find and remove the /T's from form;
rsubmit;
data my_exhibits_10k_t;	
	set my_exhibits_10k_no_a2;
	where form like '%T%';
run;
proc download data=my_exhibits_10k_t out=my_exhibits_10k_t; run;
data my_exhibits_10k_no_t;	
	set my_exhibits_10k_no_a2;
	where form not like '%T%';
run;
proc download data=my_exhibits_10k_no_t out=my_exhibits_10k_no_t; run;
endrsubmit;

*Find and remove the /T's from type;
rsubmit;
data my_exhibits_10k_t2;	
	set my_exhibits_10k_no_t;
	where type like '%T%';
run;
proc download data=my_exhibits_10k_t2 out=my_exhibits_10k_t2; run;
data my_exhibits_10k_no_t2;	
	set my_exhibits_10k_no_t;
	where type not like '%T%';
run;
proc download data=my_exhibits_10k_no_t2 out=my_exhibits_10k_no_t2; run;
endrsubmit;

*Find and remove the .PDFs from form;
rsubmit;
data my_exhibits_10k_pdfs;	
	set my_exhibits_10k_no_t2;
	where form like '%PDF%';
run;
proc download data=my_exhibits_10k_pdfs out=my_exhibits_10k_pdfs; run;
data my_exhibits_10k_no_pdfs;	
	set my_exhibits_10k_no_t2;
	where form not like '%PDF%';
run;
proc download data=my_exhibits_10k_no_pdfs out=my_exhibits_10k_no_pdfs; run;
endrsubmit;

*Find and remove the .PDFs from type;
rsubmit;
data my_exhibits_10k_pdfs2;	
	set my_exhibits_10k_no_pdfs;
	where type like '%PDF%';
run;
proc download data=my_exhibits_10k_pdfs2 out=my_exhibits_10k_pdfs2; run;
data my_exhibits_10k_no_pdfs2;	
	set my_exhibits_10k_no_pdfs;
	where type not like '%PDF%';
run;
proc download data=my_exhibits_10k_no_pdfs2 out=my_exhibits_10k_no_pdfs2; run;
endrsubmit;

*Find and remove where fsize=0;
rsubmit;
data my_exhibits_10k_0_fsize;	
	set my_exhibits_10k_no_pdfs2;
	where fsize=0;
run;
proc download data=my_exhibits_10k_0_fsize out=my_exhibits_10k_0_fsize; run;
data my_exhibits_10k_not0_fsize;	
	set my_exhibits_10k_no_pdfs2;
	where fsize^=0;
run;
proc download data=my_exhibits_10k_not0_fsize out=my_exhibits_10k_not0_fsize; run;
endrsubmit;

*Add counts;
rsubmit;
data my_exhibits_10k_not0_fsize;	
	set my_exhibits_10k_not0_fsize;
	&columnyear. = year(fdate);
	label &columnyear.="year";
run;
proc sort data=my_exhibits_10k_not0_fsize;
    by cik &columnyear.;
run;
proc sql;
	create table 		my_exhibits_10k_counts1 as
	select  			a.*, count(a.cik) as yearly_filing_count_total
	from 				my_exhibits_10k_not0_fsize a
	group by 			a.cik, a.&columnyear.
	order by			a.cik, a.&columnyear.;
quit;
proc download data=my_exhibits_10k_counts1 out=my_exhibits_10k_counts1; run;
data my_exhibits_10k_counts2;	
	set my_exhibits_10k_counts1;
	by cik &columnyear.;
	if first.&columnyear. then yearly_filing_count=0;
	yearly_filing_count+1;
	*if last.&columnyear. then output;
run;
proc download data=my_exhibits_10k_counts2 out=my_exhibits_10k_counts2; run;
endrsubmit;

*Find and remove observations with multiple year counts;
rsubmit;
data my_exhibits_10k_multi my_exhibits_10k_single;	
	set my_exhibits_10k_counts2;
	if yearly_filing_count_total>1 then do;
	    output my_exhibits_10k_multi;
    end;
	else do;
	    output my_exhibits_10k_single;
	end;
run;
proc download data=my_exhibits_10k_multi out=my_exhibits_10k_multi; run;
proc download data=my_exhibits_10k_single out=my_exhibits_10k_single; run;
endrsubmit;

*Add filing addresses;
rsubmit;
data my_exhibits_10k_final(drop=tempurl tempurl2);	
	format local_url_htm $100. local_url_txt $100. web_url_htm $100. web_url_txt $100.;
	set my_exhibits_10k_single;
	local_url_txt = cats("/wrds/sec/archives/",FNAME);
	web_url_txt = cats("http://www.sec.gov/Archives/",FNAME);
	tempurl = substr(FNAME,1,find(FNAME,".txt",1)-1);
	tempurl2 = compress(tempurl,'- ');
	local_url_htm = cats("/wrds/sec/archives/",tempurl,"-index.htm");
	web_url_htm = cats("http://www.sec.gov/Archives/",tempurl2,"/",FILENAME);
	cik_short = substr(FNAME,find(FNAME,"data/",1)+5,find(FNAME,"/",find(FNAME,"data/",1)+5)-find(FNAME,"data/",1)-5);
	label local_url_txt="local URL to text file"
          web_url_txt="web URL to text file"
          local_url_htm="local URL to htm file"
          web_url_htm="web URL to htm file"
          cik_short="cik_short";
run;
proc download data=my_exhibits_10k_final out=my_exhibits_10k_final; run;
endrsubmit;

***TEST***;
proc sql;
	create table 		test_form as
	select  			unique a.form, count(a.form) as form_count
	from 				my_exhibits a
    group by 			a.form;
quit;
proc sql;
	create table 		test_type as
	select  			unique a.type, count(a.type) as type_count
	from 				my_exhibits a
    group by 			a.type;
quit;
***END TEST***;

***TEST***;
proc sql;
	create table 		test_form2 as
	select  			unique a.form, count(a.form) as form_count
	from 				My_exhibits_10k_final a
    group by 			a.form;
quit;
proc sql;
	create table 		test_type2 as
	select  			unique a.type, count(a.type) as type_count
	from 				My_exhibits_10k_final a
    group by 			a.type;
quit;
***END TEST***;


/*
*Print last downloaded data;
proc print data=&syslast(obs=100); 
  by CIK;
  id &columnyear.;
  var coname web_url_htm;
run;
*/


*Make local_backup of data;
data &testdatalibrary..my_exhibits_10k_final;	
	set my_exhibits_10k_final;
run;
*Restore from backup;
data my_exhibits_10k_final;	
	set &testdatalibrary..my_exhibits_10k_final;
run;
rsubmit;
proc upload data=my_exhibits_10k_final out=my_exhibits_10k_final; run;
endrsubmit;

*Select top 1000;
rsubmit;
proc sql outobs=1000;
	create table 	my_exhibits_10k_1000 as 
	select 			a.*
	from 			my_exhibits_10k_final as a;
quit;
proc download data=my_exhibits_10k_1000 out=my_exhibits_10k_1000; run;
endrsubmit;

*Select top 100;
rsubmit;
proc sql outobs=100;
	create table 	my_exhibits_10k_100 as 
	select 			a.*
	from 			my_exhibits_10k_final as a;
quit;
proc download data=my_exhibits_10k_100 out=my_exhibits_10k_100; run;
endrsubmit;



*=====================================================================;
*Product Description Macro;
*=====================================================================; 
*Include Macro locally;
%include "&projectrootdirectory.\SAS\lineparse_Brad.sas";
%include "&projectrootdirectory.\SAS\textparse_Brad.sas";
%include "&projectrootdirectory.\SAS\paraparse_Brad.sas";
%include "&projectrootdirectory.\SAS\lineparaparse_Brad.sas";

*Upload macros to WRDS server;
rsubmit;
filename rfile1 "lineparse_Brad.sas";
proc upload infile="H:\Research\Web_Crawler\SAS\lineparse_Brad.sas" outfile=rfile1;
run;
filename rfile2 "textparse_Brad.sas";
proc upload infile="H:\Research\Web_Crawler\SAS\textparse_Brad.sas" outfile=rfile2;
run;
filename rfile3 "paraparse_Brad.sas";
proc upload infile="H:\Research\Web_Crawler\SAS\paraparse_Brad.sas" outfile=rfile3;
run;
filename rfile4 "lineparaparse_Brad.sas";
proc upload infile="H:\Research\Web_Crawler\SAS\lineparaparse_Brad.sas" outfile=rfile4;
run;
endrsubmit;

/*LINEPARSE_BRAD macro:  WRDS-SEC Line-by-Line Parser for a given text or regular expression preserving tabular format preserving tabular format.*/
/*
rsubmit;
%include "lineparse_Brad.sas";
%let string=Item 2.;
*%LINEPARSE_BRAD(INSET=my_exhibits_10k_final,OUTSET=lineparse_output,FNAME_FULL=local_url_txt,TSTR=&string.);
*%LINEPARSE(INSET=my_exhibits_10k_final,OUTSET=lineparse_output,FNAME_FULL=local_url_txt,TSTR=&string.);
proc download data=lineparse_output out=lineparse_output;
run;
endrsubmit;
*/




*TEXTPARSE_BRAD macro:  Parses WRDS-SEC filings for any hits that match a given string or regular expression, and extracts in addition to the match line, a pre-specified number of preceding characters.;
rsubmit;
%include "textparse_Brad.sas";
%let string=Item 2.;
%let num=300;
%TEXTPARSE_BRAD(INSET=my_exhibits_10k_100,OUTSET=textparse_output,FNAME_FULL=local_url_txt,TSTR=&string.,ln=&num.);
/*%TEXTPARSE(INSET=my_exhibits_10k_final,OUTSET=textparse_output,FNAME_FULL=local_url_txt,TSTR=&string.,ln=&num.);*/
proc download data=textparse_output out=textparse_output;
run;
endrsubmit;
/*
rsubmit;
%include "textparse_Brad.sas";
%let string=Item 2.;
%let num=300;
%TEXTPARSE_BRAD(INSET=my_exhibits_10k_1000,OUTSET=textparse_output2,FNAME_FULL=local_url_txt,TSTR=&string.,ln=&num.);
proc download data=textparse_output2 out=textparse_output2;
run;
endrsubmit;

*PARAPARSE_BRAD macro:  Parses WRDS-SEC filings and extracts a paragraph with pre-specified number of text lines around a given match string;
rsubmit;
%include "paraparse_Brad.sas";
%include "lineparaparse_Brad.sas";
%let string=Item 2.;
%let num2=20;
%PARAPARSE_BRAD(INSET=my_exhibits_10k_final,OUTSET=paraparse_output,FNAME_FULL=local_url_txt,TSTR=&string.,NLINE=&num2.);
proc download data=paraparse_output out=paraparse_output;
run;
endrsubmit;
*/

*=====================================================================;
*Find non-matches;
*=====================================================================;
rsubmit;
data textparse_nomatch textparse_match;
    set textparse_output;
    if Match=0 then output textparse_nomatch;
	else output textparse_match;
run;
proc download data=textparse_nomatch out=textparse_nomatch;
run;
proc download data=textparse_match out=textparse_match;
run;
endrsubmit;
*=====================================================================;
*Cleanup descriptions;
*=====================================================================;
rsubmit;
data textparse_match(drop=&paragraphcol. &paragraphcol._compress1-&paragraphcol._compress3 &paragraphcol._compbl &paragraphcol._trim);
    set textparse_match;
    &paragraphcol._compress1=compress(&paragraphcol.,,"p");  *Compressing punctuation characters;
    &paragraphcol._compress2=compress(&paragraphcol._compress1,"+-","d");  *Compressing digits and plus/minus signs characters;
    &paragraphcol._compress3=compress(&paragraphcol._compress2,,"c");  *Compressing control characters;
    &paragraphcol._compbl=compbl(&paragraphcol._compress3);
    &paragraphcol._trim=trim(&paragraphcol._compbl);
    &paragraphcol._upcase = upcase(&paragraphcol._trim);
run;
proc download data=textparse_match out=textparse_match;
run;
data textparse_match(rename=(&paragraphcol._upcase=&paragraphcol.));
    set textparse_match;
    if &paragraphcol._upcase="" then delete;
run;
*Replace SAS words that break macro;
data textparse_match2;
    set textparse_match;
	&paragraphcol. = tranwrd(&paragraphcol.,'AND','_AND');
	&paragraphcol. = tranwrd(&paragraphcol.,'OR','_OR');
	&paragraphcol. = tranwrd(&paragraphcol.,'NOT','_NOT');
	&paragraphcol. = tranwrd(&paragraphcol.,'IN','_IN');
	&paragraphcol. = tranwrd(&paragraphcol.,'ON','_ON');
	&paragraphcol. = tranwrd(&paragraphcol.,'BETWEEN','_BETWEEN');
	ob=_N_;
	tempnum1= put(ob, z7.0);
run;
proc download data=textparse_match2 out=textparse_match2;
run;
endrsubmit;

data &inputdataset.(drop=ob tempnum1-tempnum6);
    format id $30.;
    set textparse_match2;
	tempnum2=compress(tempnum1,,"p");  *Compressing decimals characters;
    tempnum3=compress(tempnum2,,"s");  *Compressing space characters;
    tempnum4=compress(tempnum3,,"t");  *Trims trailing blanks;
    tempnum5=compbl(tempnum4);
    tempnum6=trim(tempnum5);
	id=cats("&columntitle.",tempnum6);
run;
proc datasets lib=work nolist; delete textparse_match2 ; quit; run; 

*=====================================================================;
**Make local_backup of final data;;
*=====================================================================;
data &testdatalibrary..&inputdataset.;	
	set &inputdataset.;
run;
*Restore from backup;
data &inputdataset.;	
	set &testdatalibrary..&inputdataset.;
run;



*=====================================================================;
*Dates used for analysis;
*=====================================================================;
/*
proc sql noprint;
    create table 		dates as
    select  			unique a.&columnyear.
    from 				&inputdataset. a;
quit;
data _null_;
	set dates end=last;
	call symputx("datesid"||left(put(_n_,4.)), trim(left(&columnyear.)),L);
	if last then call symput ("nobsdates", _n_); 
run;
proc datasets lib=work nolist; delete dates ; quit; run; 
*/


*=====================================================================;
*Percentiles used for analysis;
*=====================================================================;
*Create lookup table for percentiles;
data percentiles;
   format  Confidence_Level 5.3;
   input  Confidence_Level;
   datalines;
.99
.95
.90
; 
data percentiles0;
    format  Confidence_Pct z4.1 Significance_Level 5.3 Significance_Pct z5.1;
    set percentiles;
	Confidence_Pct=Confidence_Level*100;
    Significance_Level=1-Confidence_Level;
    Significance_Pct=Significance_Level*100;
	Confidence_lbl0 = put(Confidence_Pct, z4.1);
    Significance_lbl0 = put(Significance_Pct, z5.1);
run;
data percentiles0(drop=Confidence_lbl0-Confidence_lbl5 Significance_lbl0-Significance_lbl5);
    format Confidence_lbl $6. Significance_lbl $7.;
    set percentiles0;
	Confidence_lbl1=compress(Confidence_lbl0,,"p");  *Compressing decimals characters;
	Confidence_lbl2=compress(Confidence_lbl1,,"s");  *Compressing space characters;
    Confidence_lbl3=compress(Confidence_lbl2,,"t");  *Trims trailing blanks;
    Confidence_lbl4=compbl(Confidence_lbl3);
    Confidence_lbl5=trim(Confidence_lbl4);
    Confidence_lbl=cats(Confidence_lbl5,"pct");
	Significance_lbl1=compress(Significance_lbl0,,"p");  *Compressing decimals characters;
	Significance_lbl2=compress(Significance_lbl1,,"s");  *Compressing space characters;
    Significance_lbl3=compress(Significance_lbl2,,"t");  *Trims trailing blanks;
    Significance_lbl4=compbl(Significance_lbl3);
    Significance_lbl5=trim(Significance_lbl4);
    Significance_lbl=cats(Significance_lbl5,"pct");
run;
proc datasets lib=work nolist; delete percentiles ; quit; run; 
proc sql noprint;
    create table 		percentiles as
    select  			a.Confidence_Level, a.Confidence_Pct, a.Confidence_lbl, a.Significance_Level, a.Significance_Pct, a.Significance_lbl
    from 				percentiles0 a;
quit;
proc datasets lib=work nolist; delete percentiles0 ; quit; run; 
data _null_;
	set percentiles end=last;
	call symputx("Confidence_lbl_id"||left(put(_n_,4.)), trim(left(Confidence_lbl)),L);
	call symputx("Significance_lvl_id"||left(put(_n_,4.)), trim(left(Significance_Level)),L);
	if last then call symput ("Percentile_nobs", _n_); 
run;
proc datasets lib=work nolist; delete percentiles ; quit; run; 


*=====================================================================;
*Explode Macro;
*=====================================================================; 

%macro explode(text=,dataset=,delim=,arrayref=);
    %put ### START. Explode Macro on <&dataset.> in column <&text.> ###; %put;
    %if %length(&dataset) = 0 %then %do;
        %let i=0;
        %let largestword = 8;
        %local returnvalue;
        %do %until (&&word&i=%str( ));
            %let i=%eval(&i+1);
            %let word&i= %scan(&text,&i,&delim);
            %if &&word&i^=%str( ) %then %do;
                %let returnvalue = &returnvalue %str(%')&&word&i%str(%'), ;
                %if %length(&returnvalue) > &largestword %then %let largestword = %length(&returnvalue);
            %end;
        %end;
        %let i = %eval (&i - 1);
        %let returnvalue = array &arrayref (&i) $ &largestword _TEMPORARY_ (&returnvalue;
        %let end = %eval(%eval(%length(&returnvalue)) - 2);
        %let returnvalue = %substr(%bquote(&returnvalue),1,&end);
        %let returnvalue = &returnvalue );
        &returnvalue;
    %end;
    %else %do;
        proc sql noprint;
        select   count(*) 
        into     :nObs_explode
        from     &dataset;
        quit;
        %let largestWord=8;
        %let maxWords=0;
        %do k=1 %to &nObs_explode;
            data _null_;
                pointer=&k;
                set &dataset point=pointer;
                call symput('toSplit',trim(&text)); 
                stop;
            run;
            %let i=0;
            %do %until (&&word&i=%str( ));
                %let i=%eval(&i+1);
                %let word&i= %scan(&toSplit,&i,&delim);
                %if &&word&i^=%str( ) %then %do;
                    %if %length(&&word&i) > &largestword %then %let largestword = %length(&&word&i);
                    %if %eval(&i > &maxWords) %then %let maxwords=&i;
                %end;
            %end;
        %end;
        data &dataset._out;
            attrib _part length=$&largestword;
            set &dataset;
            array &arrayRef (&maxWords) $ &largestword _part1-_part&maxWords;
            _i=0;
            do until (compress(_part)='');
                _i = _i + 1;
                _part = scan(&text,_i,' ');
                if compress(_part) ^= ' ' then &arrayRef(_i) = _part;
            end;
            drop _part _i;
        run;
        data &dataset._out;
		    set &dataset._out;
			label %do n = 1 %to &maxWords.; _part&n.="_part&n." %end; ;
		run;
    %end;
%mend explode;


*=====================================================================;
*Split Macro;
*=====================================================================;  

%macro split(npct=,colpre=,colyear=,inputds=,outputds=,col=); 
    %put ### START. Split Macro ###; %put;
	%put #####################################################################;
    %put 1.   Initial Splitting;
    %put #####################################################################; %put;

    %put ### Drop all columns except for the one with the desired text ###; %put;
    data &inputds._trim(keep= &col.);
        set &inputds.;
    run;
    %put ### Determine number of observations in dataset with descriptions ###; %put;
    data _null_;
	    set &inputds._trim end=last;
	    if last then call symput ("ndsn", _n_); 
    run;
    data %do j = 1 %to &ndsn.; &colpre.&j. %end; ; 
        retain numlines; 
        set &inputds._trim nobs=nobs; 
        if _n_ eq 1 
            then do; 
                if mod(nobs,&ndsn.) eq 0 then numlines=int(nobs/&ndsn.); 
                else numlines=int(nobs/&ndsn.)+1; 
            end; 
        if _n_ le numlines then output &colpre.1; 
            %do j = 2 %to &ndsn.; 
                else if _n_ le (&j.*numlines) then output &colpre.&j.; 
            %end; 
    run; 
	%do m = 1 %to &ndsn.; 
        data &colpre.&m.(drop=numlines);
            set &colpre.&m.;
        run;
    %end;

	%put #####################################################################;
    %put 2.   Explode Macro;
    %put #####################################################################; %put;

    %put ### Explode descriptions and delete temporary datasets ###; %put;
    %do l = 1 %to &ndsn.; 
        %explode(text=&col., dataset=&colpre.&l., delim=%str( ), arrayRef=y&l.);
    %end;

    proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; &colpre.&m. %end;  ; quit; run; 

    %put ### Transpose descriptions,Create ID, and add year variable to *_out_ ###; %put;
    %do m = 1 %to &ndsn.; 
        proc transpose data=&colpre.&m._out out=&colpre.&m._out_t;
            var _ALL_;
        run;
        data &colpre.&m._out_t(drop=_Name_ _Label_);
            set &colpre.&m._out_t(rename=(COL1=&col.));
	        if _N_=1 then delete;
        run;
        data &colpre.&m._out_t;
            set &colpre.&m._out_t;
	        &col. = compress(&col.,'_');
        run;
	    data &colpre.&m._out_t2;
            set &colpre.&m._out_t;
	        tempnum1= put(&m., z7.0);
		run;
        data &colpre.&m._out_t2(drop=tempnum1-tempnum6);
            format id $30.;
            set &colpre.&m._out_t2;
	        tempnum2=compress(tempnum1,,"p");
	        tempnum3=compress(tempnum2,,"s");
            tempnum4=compress(tempnum3,,"t");
            tempnum5=compbl(tempnum4);
            tempnum6=trim(tempnum5);
            id=cats("&colpre.",tempnum6);
        run;
        proc sql noprint;
            create table 		&colpre.&m._out_t2a as
            select  			a.*,b.&colyear.
            from 				&colpre.&m._out_t2 a
	        inner join          textparse_match_final b
            on                  a.id=b.id;
        quit;
	    data &colpre.&m._out_t2a(drop=id);
            set &colpre.&m._out_t2a;
	    run;
	    proc sort data=&colpre.&m._out_t2a;
            by &col.;
        run;
    %end;
    proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; &colpre.&m._out %end;  ; quit; run;

    %put ### Sort the datasets for merging, create summary statistics, create ID, and add year variable to *_out_t_stats ###; %put;
    %do m = 1 %to &ndsn.; 
	    proc sort data=&colpre.&m._out_t;
	        by &col.;
        run;
	    proc means data=&colpre.&m._out_t noprint;
	        class &col.;
            output out=&colpre.&m._out_t_stats;
        run;
		proc sql noprint;
            select   _FREQ_ 
            into     :total_words_&m.
            from     &colpre.&m._out_t_stats
			where    _TYPE_=0;
        quit;
	    data &colpre.&m._out_t_stats;
            set &colpre.&m._out_t_stats;
			total_percentage=_FREQ_ / &&total_words_&m.;
        run;
        proc sort data=&colpre.&m._out_t_stats;
            by descending _FREQ_ &col.;
        run;
	    data &colpre.&m._out_t2_stats;
            set &colpre.&m._out_t_stats;
	        tempnum1= put(&m., z7.0);
		run;
        data &colpre.&m._out_t2_stats(drop=tempnum1-tempnum6);
            format id $30.;
            set &colpre.&m._out_t2_stats;
	        tempnum2=compress(tempnum1,,"p");
	        tempnum3=compress(tempnum2,,"s"); 
            tempnum4=compress(tempnum3,,"t"); 
            tempnum5=compbl(tempnum4);
            tempnum6=trim(tempnum5);
            id=cats("&colpre.",tempnum6);
        run;
        proc sql noprint;
            create table 		&colpre.&m._out_t2a_stats as
            select  			a.*,b.&colyear.
            from 				&colpre.&m._out_t2_stats a
	        inner join          textparse_match_final b
            on                  a.id=b.id;
        quit;
	    data &colpre.&m._out_t2a_stats(drop=id);
            set &colpre.&m._out_t2a_stats;
	    run;
	    proc sort data=&colpre.&m._out_t2a_stats;
            by descending _FREQ_ &col.;
        run;
    %end;

    %put ### Create global dictionary (year-level) ###; %put;
    data global_year;
        set %do m = 1 %to &ndsn.; &colpre.&m._out_t2a %end; ;  
    run;
    proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; &colpre.&m._out_t %end;  ; quit; run;
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; &colpre.&m._out_t2 %end;  ; quit; run;
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; &colpre.&m._out_t2a %end;  ; quit; run;
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; &colpre.&m._out_t_stats %end;  ; quit; run;
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; &colpre.&m._out_t2_stats %end;  ; quit; run;
    

	%put #####################################################################;
    %put 3A.  Global Dictionary (aggregate);
    %put #####################################################################; %put; 

	%put ### Create global dictionary (aggregate) ###; %put; 
    data global(drop=&colyear.);
        set global_year;  
    run;

    %put ### Save global dictionary to test directories ###; %put;
	data &testdatalibrary..global;
        set global;
    run;
    data &emdatalibrary..global;
        set global;
    run;

	%put ### Compute summary statistics for global dictionary ###; %put;
	proc means data=global noprint;
		class &col.;
		output out=global_stats;
	run;
    proc sql noprint;
        select   _FREQ_
        into     :global_total_words
        from     global_stats
		where    _TYPE_=0;
    quit;
	data global_stats;
        set global_stats;
        total_percentage=_FREQ_ / &global_total_words.;
    run;
	proc sort data=global_stats;
	    by descending _FREQ_ &col.;
    run;
	proc datasets lib=work nolist; delete global ; quit; run;

    %put ### Find the top x% global entries ###; %put;
    proc sql noprint;
        select              count(&col.) 
        into                :global_distinct_words
        from                global_stats
        where               _TYPE_=1;
    quit;
	data global_stats;
        set global_stats;
        %do z = 1 %to &npct.;  
		    Word_Cutoff_&&Confidence_lbl_id&z.=ceil(&&Significance_lvl_id&z.*&global_distinct_words.);
        %end;
		obnum=_N_;
		obnumminus1=obnum-1;
    run;
	data global_stats(drop= %do z = 1 %to &npct.; Word_Cutoff_&&Confidence_lbl_id&z. %end; obnum obnumminus1);
        set global_stats;
        if _TYPE_=0 then do;
		    %do z = 1 %to &npct.;  
		        Word_dv_&&Confidence_lbl_id&z.= -1;
            %end;
        end;
		else if _TYPE_=1 then do;
		    %do z = 1 %to &npct.;  
                if obnumminus1<=Word_Cutoff_&&Confidence_lbl_id&z. then do;
			        Word_dv_&&Confidence_lbl_id&z. = 1;
		        end;
		        else do;
		            Word_dv_&&Confidence_lbl_id&z. = 0;
                end;
            %end;
        end;
    run; 
    proc sort data=global_stats;
        by %do z = 1 %to &npct.; descending Word_dv_&&Confidence_lbl_id&z. %end; descending _FREQ_ &col.;
    run;

	%put ### Create global tables based on the percentiles ###; %put;
    %do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_&&Confidence_lbl_id&z. as
            select  			a.&col., a._TYPE_, a._FREQ_
            from 				global_stats a
            where               Word_dv_&&Confidence_lbl_id&z.=0
            order by            a.&col.;
        quit;
	%end;

    %put ### Sort the datasets for merging and create summary statistics for the global trimmed percentiles ###; %put;
	%do z = 1 %to &npct.;
        proc sort data=global_&&Confidence_lbl_id&z.;
	        by &col.;
        run;
        proc sql noprint;
            create table global_stats_&&Confidence_lbl_id&z. as
            select       a.*, sum(_FREQ_) as total
            from         global_&&Confidence_lbl_id&z. a;
        quit;
        data global_stats_&&Confidence_lbl_id&z.;
            set global_stats_&&Confidence_lbl_id&z.;
            total_percentage=_FREQ_ / total;
        run;
        proc sort data=global_stats_&&Confidence_lbl_id&z.;
            by descending _TYPE_ &col.;
        run;
	%end;
	proc datasets lib=work nolist; delete %do z = 1 %to &npct.; global_&&Confidence_lbl_id&z. %end; ; quit; run;

    %put ### Get the overall grand totals for global dataset ###; %put;
    %do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_stats_0_&&Confidence_lbl_id&z. as
            select  			unique a.total
            from 				global_stats_&&Confidence_lbl_id&z. a;
        quit;
        data global_stats_0_&&Confidence_lbl_id&z.(rename=(total=_FREQ_));
		    set global_stats_0_&&Confidence_lbl_id&z.;
        run;
	%end;

	%put ### Get the distinct grand totals for global dataset ###; %put;
	%do z = 1 %to &npct.;
        data global_stats_1_&&Confidence_lbl_id&z.;
            set global_stats_&&Confidence_lbl_id&z.;
            if &col.="" then delete;
        run;
        proc sql noprint;
            create table 		global_stats_1_u_&&Confidence_lbl_id&z. as
            select  			unique a.&col., count(a.&col.) as counts
            from 				global_stats_1_&&Confidence_lbl_id&z. a;
        quit;
	    proc sql noprint;
            create table 		global_stats_1_u2_&&Confidence_lbl_id&z. as
            select  			unique a.counts
            from 				global_stats_1_u_&&Confidence_lbl_id&z. a;
        quit;  
	%end;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_stats_1_&&Confidence_lbl_id&z. %end;  ; quit; run;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_stats_1_u_&&Confidence_lbl_id&z. %end;  ; quit; run;

    %put ### Combine global table *_stats_0 and *_stats_1_u2 ###; %put;
	%do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_stats_2_&&Confidence_lbl_id&z. as
            select  			a._FREQ_, b.counts
            from 				global_stats_0_&&Confidence_lbl_id&z. a, global_stats_1_u2_&&Confidence_lbl_id&z. b;
        quit;
		data global_stats_2_&&Confidence_lbl_id&z.(rename=(_FREQ_=glob_grnd_totals_agg_&&Confidence_lbl_id&z. counts=glob_dist_totals_agg_&&Confidence_lbl_id&z.));
            set global_stats_2_&&Confidence_lbl_id&z.;  
        run;
	%end;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_stats_0_&&Confidence_lbl_id&z. %end;  ; quit; run;
    proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_stats_1_u2_&&Confidence_lbl_id&z. %end;  ; quit; run;


	%put #####################################################################;
    %put 3B.  Global Dictionary (year-level);
    %put #####################################################################; %put; 

    %put ### Compute summary statistics for global yearly dictionary ###; %put;
	proc sort data=global_year;
	    by &colyear. &col.;
    run;
	proc means data=global_year noprint;
	    by &colyear.;
		class &col.;
		output out=global_stats_year0;
	run;
	proc sql noprint;
        create table        global_stats_year0_temp as
        select              a.&colyear., a._FREQ_ 
        from                global_stats_year0 a
        where               _TYPE_=0;
    quit;
    data global_stats_year0_temp(rename=(_FREQ_=global_yearly_total_words));
        set global_stats_year0_temp;  
    run;
	proc sql noprint;
        create table 		global_stats_year as
        select  			a.*,b.global_yearly_total_words
        from 				global_stats_year0 a
	    full join           global_stats_year0_temp b
        on                  a.&colyear.=b.&colyear.;
    quit;
    data global_stats_year;
        set global_stats_year;  
        total_percentage=_FREQ_ / global_yearly_total_words;
    run;
	proc sort data=global_stats_year;
	    by &colyear. descending _FREQ_ &col.;
    run;
	proc datasets lib=work nolist; delete global_year global_stats_year0 global_stats_year0_temp ; quit; run;

	%put ### Find the top x% global yearly entries ###; %put;
	proc sql noprint;
        create table 		global_distinct_words_temp as
        select  			a.&colyear., count(a.&col.) as global_distinct_words_yearly
        from 				global_stats_year a
        where               a._TYPE_=1
        group by            a.&colyear.;
    quit;
	proc sql noprint;
        create table 		global_stats_year1 as
        select  			a.*,b.global_distinct_words_yearly
        from 				global_stats_year a
	    full join           global_distinct_words_temp b
        on                  a.&colyear.=b.&colyear.;
    quit;
	proc datasets lib=work nolist; delete global_stats_year ; quit; run;
	data global_stats_year1;
        set global_stats_year1;
        %do z = 1 %to &npct.;  
		    Word_Cutoff_&&Confidence_lbl_id&z.=ceil(&&Significance_lvl_id&z.*global_distinct_words_yearly);
        %end;
    run;
	data global_stats_year1;
        set global_stats_year1;
        by &colyear.;
	    if first.&colyear. then do;
            obnum_year=0;
			obnumminus1_year=-1;
		end;
	    obnum_year+1;
        obnumminus1_year+1;
    run;
	data global_stats_year1(drop= %do z = 1 %to &npct.; Word_Cutoff_&&Confidence_lbl_id&z. %end; obnum_year obnumminus1_year);
        set global_stats_year1;
        if _TYPE_=0 then do;
		    %do z = 1 %to &npct.;  
		        Word_dv_&&Confidence_lbl_id&z.= -1;
            %end;
        end;
		else if _TYPE_=1 then do;
		    %do z = 1 %to &npct.;  
                if obnumminus1_year<=Word_Cutoff_&&Confidence_lbl_id&z. then do;
			        Word_dv_&&Confidence_lbl_id&z. = 1;
		        end;
		        else do;
		            Word_dv_&&Confidence_lbl_id&z. = 0;
                end;
            %end;
        end;
    run; 
	data global_stats_year;
        set global_stats_year1;
	run;
	proc sort data=global_stats_year;
	    by &colyear. %do z = 1 %to &npct.; descending Word_dv_&&Confidence_lbl_id&z. %end; descending _FREQ_ &col.;
    run;
	proc datasets lib=work nolist; delete global_stats_year1 ; quit; run;

    %put ### Create global tables based on the percentiles by year ###; %put;
    %do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_year_&&Confidence_lbl_id&z. as
            select  			a.&colyear., a.&col., a._TYPE_, a._FREQ_
            from 				global_stats_year a
            where               Word_dv_&&Confidence_lbl_id&z.=0
            order by            a.&colyear., a.&col.;
        quit;
	%end;

    %put ### Sort the datasets for merging and create summary statistics for the global trimmed percentiles ###; %put;
	%do z = 1 %to &npct.;
        proc sort data=global_year_&&Confidence_lbl_id&z.;
	        by &colyear. &col.;
        run;
        proc sql noprint;
            create table        global_stats_year_&&Confidence_lbl_id&z. as
            select              a.*, sum(_FREQ_) as total_year
            from                global_year_&&Confidence_lbl_id&z. a
            group by            a.&colyear.;
        quit;

        data global_stats_year_&&Confidence_lbl_id&z.;
            set global_stats_year_&&Confidence_lbl_id&z.;
            total_percentage_year=_FREQ_ / total_year;
        run;
        proc sort data=global_stats_year_&&Confidence_lbl_id&z.;
            by &colyear. descending _TYPE_ &col.;
        run;
	%end;
	proc datasets lib=work nolist; delete %do z = 1 %to &npct.; global_year_&&Confidence_lbl_id&z. %end; ; quit; run;

    %put ### Get the overall grand totals for global yearly dataset ###; %put;
    %do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_stats_year_0_&&Confidence_lbl_id&z. as
            select  			unique a.&colyear.,a.total_year
            from 				global_stats_year_&&Confidence_lbl_id&z. a
            order by            a.&colyear.;
        quit;
        data global_stats_year_0_&&Confidence_lbl_id&z.(rename=(total_year=_FREQ_));
		    set global_stats_year_0_&&Confidence_lbl_id&z.;
        run;
	%end;

	%put ### Get the distinct grand totals for global yearly dataset ###; %put;
	%do z = 1 %to &npct.;
        data global_stats_year_1_&&Confidence_lbl_id&z.;
            set global_stats_year_&&Confidence_lbl_id&z.;
            if &col.="" then delete;
        run;
        proc sql noprint;
            create table 		global_stats_year_1_u_&&Confidence_lbl_id&z. as
            select  			unique a.&colyear., a.&col., count(a.&col.) as counts
            from 				global_stats_year_1_&&Confidence_lbl_id&z. a
            group by            a.&colyear.;
        quit;
	    proc sql noprint;
            create table 		global_stats_year_1_u2_&&Confidence_lbl_id&z. as
            select  			unique a.&colyear.,a.counts
            from 				global_stats_year_1_u_&&Confidence_lbl_id&z. a
            order by            a.&colyear.;
        quit;  
	%end;
	proc datasets lib=work nolist; delete %do z = 1 %to &npct.; global_stats_year_1_&&Confidence_lbl_id&z. %end;  ; quit; run;
	proc datasets lib=work nolist; delete %do z = 1 %to &npct.; global_stats_year_1_u_&&Confidence_lbl_id&z. %end;  ; quit; run;

    %put ### Combine global table *_stats_0 and *_stats_1_u2 ###; %put;
	%do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_stats_year_2_&&Confidence_lbl_id&z. as
            select  			a.&colyear.,a._FREQ_, b.counts
            from 				global_stats_year_0_&&Confidence_lbl_id&z. a, global_stats_year_1_u2_&&Confidence_lbl_id&z. b
            where               a.&colyear.=b.&colyear.;
        quit;
		data global_stats_year_2_&&Confidence_lbl_id&z.(rename=(_FREQ_=glob_grnd_totals_year_&&Confidence_lbl_id&z. counts=glob_dist_totals_year_&&Confidence_lbl_id&z.));
            set global_stats_year_2_&&Confidence_lbl_id&z.;  
        run;
	%end;
	proc datasets lib=work nolist; delete %do z = 1 %to &npct.; global_stats_year_0_&&Confidence_lbl_id&z. %end;  ; quit; run;
    proc datasets lib=work nolist; delete %do z = 1 %to &npct.; global_stats_year_1_u2_&&Confidence_lbl_id&z. %end;  ; quit; run;

 
	%put #####################################################################;
    %put 4A.  Individual Dictionaries (aggregate);
    %put #####################################################################; %put; 

	%put ### Create individual dictionary for the most commonly used percentiles of words ###; %put;
	%do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_excluded_&&Confidence_lbl_id&z. as
            select  			a.&col.
            from 				global_stats a
            where               Word_dv_&&Confidence_lbl_id&z.=1
            order by            a.&col.;
        quit;
        data _null_;
	        set global_excluded_&&Confidence_lbl_id&z. end=last;
	        call symputx("descrip_&&Confidence_lbl_id&z."||left(put(_n_,4.)), trim(left(&col.)),L);
		    if last then call symput ("nobsid_&&Confidence_lbl_id&z.", _n_); 
        run;
	%end;

	%put ### Add common word flags at aggregate-level ###; %put;
    %do m = 1 %to &ndsn.;
        data &colpre.&m._all_stats;
            set &colpre.&m._out_t2a_stats;
			if _TYPE_=0 then do;
		        %do z = 1 %to &npct.;  
		            Word_dv_&&Confidence_lbl_id&z.= -1;
                %end;
            end;
		    else if _TYPE_=1 then do;
		        %do z = 1 %to &npct.;  
				   %let temp_label =&&Confidence_lbl_id&z.;
				    if &col. in ( %do i = 1 %to &&nobsid_&temp_label.; "&&descrip_&temp_label&i." %end;) then do;
                        Word_dv_&&Confidence_lbl_id&z.=1;
                    end;
			        else do;
                        Word_dv_&&Confidence_lbl_id&z.=0;
                    end;
					
                %end;
            end;
        run;
		proc sort data=&colpre.&m._all_stats;
            by &colyear %do z = 1 %to &npct.; descending Word_dv_&&Confidence_lbl_id&z. %end; descending _FREQ_ &col.;
        run;
	%end;

    %put ### Create individual tables based on the percentiles ###; %put;
    %do m = 1 %to &ndsn.;
        %do z = 1 %to &npct.;  
	        proc sql noprint;
                create table 		&colpre.&m._&&Confidence_lbl_id&z. as
                select  			a.&colyear., a.&col., a._TYPE_, a._FREQ_
                from 				&colpre.&m._all_stats a
                where               Word_dv_&&Confidence_lbl_id&z.=0
                order by            a.&colyear., a.&col.;
            quit;
        %end;
    %end;

	%put ### Sort the datasets for merging and create summary statistics for the individual trimmed percentiles ###; %put;
    %do m = 1 %to &ndsn.; 
	    %do z = 1 %to &npct.;  
		    proc sort data=&colpre.&m._&&Confidence_lbl_id&z.;
	            by &colyear. &col.;
            run;
		    proc sql noprint;
		        create table &colpre.&m._stats_&&Confidence_lbl_id&z. as
                select       a.*, sum(a._FREQ_) as total
                from         &colpre.&m._&&Confidence_lbl_id&z. a;
            quit;
	        data &colpre.&m._stats_&&Confidence_lbl_id&z.;
                set &colpre.&m._stats_&&Confidence_lbl_id&z.;
			    total_percentage=_FREQ_ / total;
            run;
            proc sort data=&colpre.&m._stats_&&Confidence_lbl_id&z.;
                by &colyear. descending _TYPE_ &col.;
            run;
        %end;
    %end;	
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; %do z = 1 %to &npct.; &colpre.&m._&&Confidence_lbl_id&z. %end; %end; ; quit; run;

	%put ### Create a name variable for each table ###; %put;
    %do m = 1 %to &ndsn.; 
	 	data &colpre.&m._all_stats;
            set &colpre.&m._all_stats;
		    tempnum1= put(&m., z7.0);
	    run;
		data &colpre.&m._all_stats(drop=tempnum1-tempnum6);
			format id $30.;
            set &colpre.&m._all_stats;
	        tempnum2=compress(tempnum1,,"p"); 
	        tempnum3=compress(tempnum2,,"s"); 
            tempnum4=compress(tempnum3,,"t"); 
            tempnum5=compbl(tempnum4);
            tempnum6=trim(tempnum5);
            id=cats("&colpre.",tempnum6,"_all_stats");
        run;
	    %do z = 1 %to &npct.;  
	        data &colpre.&m._stats_&&Confidence_lbl_id&z.;
                set &colpre.&m._stats_&&Confidence_lbl_id&z.;
				tempnum1= put(&m., z7.0);
			run;
            data &colpre.&m._stats_&&Confidence_lbl_id&z.(drop=tempnum1-tempnum6);
			    format id $30.;
                set &colpre.&m._stats_&&Confidence_lbl_id&z.;
	            tempnum2=compress(tempnum1,,"p");
	            tempnum3=compress(tempnum2,,"s");
                tempnum4=compress(tempnum3,,"t");
                tempnum5=compbl(tempnum4);
                tempnum6=trim(tempnum5);
                id=cats("&colpre.",tempnum6,"_&&Confidence_lbl_id&z.");
            run;
        %end;
    %end;

    %put ### Get the grand totals for each individual dataset ###; %put;
    %do m = 1 %to &ndsn.; 
	    %do z = 1 %to &npct.;  
            proc sql noprint;
                create table 		&colpre.&m._stats_0_&&Confidence_lbl_id&z. as
                select  			unique a.id, a.&colyear., a.total
                from 				&colpre.&m._stats_&&Confidence_lbl_id&z. a
                order by            a.id;
            quit;
		    data &colpre.&m._stats_0_&&Confidence_lbl_id&z.(rename=(total=_FREQ_));
		        set &colpre.&m._stats_0_&&Confidence_lbl_id&z.;
            run; 
        %end;
    %end;

    %put ### Get the unique grand totals for each individual dataset ###; %put;
    %do m = 1 %to &ndsn.; 
	    %do z = 1 %to &npct.;
	        data &colpre.&m._stats_1_&&Confidence_lbl_id&z.;
                set &colpre.&m._stats_&&Confidence_lbl_id&z.;
			    if &col.="" then delete;
            run;
            proc sql noprint;
                create table 		&colpre.&m._stats_1_u_&&Confidence_lbl_id&z. as
                select  			unique a.id, a.&colyear., a.&col., count(a.&col.) as counts
                from 				&colpre.&m._stats_1_&&Confidence_lbl_id&z. a;
            quit;
		    proc sql noprint;
                create table 		&colpre.&m._stats_1_u2_&&Confidence_lbl_id&z. as
                select  			unique a.id, a.&colyear., a.counts
                from 				&colpre.&m._stats_1_u_&&Confidence_lbl_id&z. a;
            quit;
        %end;
    %end;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; %do z=1 %to &npct.; &colpre.&m._stats_1_&&Confidence_lbl_id&z. %end; %end; ; quit; run;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; %do z=1 %to &npct.; &colpre.&m._stats_1_u_&&Confidence_lbl_id&z. %end; %end; ; quit; run;

	%put ### Combine table *_stats_0 and *_stats_1_u2 ###; %put;
    %do m = 1 %to &ndsn.; 
	    %do z = 1 %to &npct.;
            proc sql noprint;
                create table 		&colpre.&m._stats_2_&&Confidence_lbl_id&z. as
                select  			a.id, a.&colyear., a._FREQ_, b.counts
                from 				&colpre.&m._stats_0_&&Confidence_lbl_id&z. a, &colpre.&m._stats_1_u2_&&Confidence_lbl_id&z. b
                where               a.id=b.id;
            quit;
        %end;
    %end;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; %do z=1 %to &npct.; &colpre.&m._stats_0_&&Confidence_lbl_id&z. %end; %end; ; quit; run;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; %do z=1 %to &npct.; &colpre.&m._stats_1_u2_&&Confidence_lbl_id&z. %end; %end; ; quit; run;

	%put ### Rename final datasets to expand number formatting in title ###; %put;
    %do m = 1 %to &ndsn.;
        proc sql noprint;
            create table 		&colpre.&m._id_temp_agg as
            select  			unique a.id
            from 				&colpre.&m._all_stats a;
        quit;
        data &colpre.&m._id_temp_agg(drop=id);
	        format id1 $30.;
	        set &colpre.&m._id_temp_agg;
		    *id1=substr(id,1,find(id,"_",1)-1);
		    id1=substr(id,1,find(id,"_",find(id,"&colpre.",1)+length("&colpre.")+1)-1);
	    run;
        data &colpre.&m._id_temp_agg;
		    format id2 $8.;
		    set &colpre.&m._id_temp_agg;
			id2=compress(id1,,"s");
		run;
		proc sql noprint;
            select   a.id2
            into     :temp_ds_name_agg
            from     &colpre.&m._id_temp_agg a;
        quit;
	    %do z = 1 %to &npct.;
            data &temp_ds_name_agg._stats_&&Confidence_lbl_id&z.;
			    format analysis_level $9.;
	            set &colpre.&m._stats_&&Confidence_lbl_id&z.;
				analysis_level= "AGGREGATE";
	        run;
        %end;
    %end;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; %do z=1 %to &npct.; &colpre.&m._stats_&&Confidence_lbl_id&z. %end; %end; ; quit; run;


    %put #####################################################################;
    %put 4B.  Individual Dictionaries (year-level);
    %put #####################################################################; %put; 

	%put ### Create individual dicitonary for the most commonly used percentiles of words by year ###; %put;
	%do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_excluded_year_&&Confidence_lbl_id&z. as
            select  			a.&colyear., a.&col.
            from 				global_stats_year a
            where               Word_dv_&&Confidence_lbl_id&z.=1
            order by            a.&colyear., a.&col.;
        quit;
	%end;

	%put ### Add common word flags at year-level ###; %put;
    %do m = 1 %to &ndsn.;
        proc sql noprint;
            select   a.&colyear.
            into     :temp_year
            from     &colpre.&m._out_t2a_stats a;
        quit;
		%do z = 1 %to &npct.;
            proc sql noprint;
			    create table &colpre.&m._out_t2a_excluded_&&Confidence_lbl_id&z. as
                select   a.*
                from     global_excluded_year_&&Confidence_lbl_id&z. a
		        where    a.&colyear.=&temp_year.;
            quit;
			data _null_;
	            set &colpre.&m._out_t2a_excluded_&&Confidence_lbl_id&z. end=last;
	            call symputx("descrip_year_&m._&&Confidence_lbl_id&z."||left(put(_n_,4.)), trim(left(&col.)),L);
		        if last then call symput ("nobsid_year_&m._&&Confidence_lbl_id&z.", _n_); 
            run;
	    %end;
        data &colpre.&m._all_stats_year;
            set &colpre.&m._out_t2a_stats;
			if _TYPE_=0 then do;
		        %do z = 1 %to &npct.;  
		            Word_dv_&&Confidence_lbl_id&z.= -1;
                %end;
            end;
		    else if _TYPE_=1 then do;
		        %do z = 1 %to &npct.;  
				   %let temp_label =&&Confidence_lbl_id&z.;
				    if &col. in ( %do i = 1 %to &&nobsid_year_&m._&temp_label.; "&&descrip_year_&m._&temp_label&i." %end;) then do;
                        Word_dv_&&Confidence_lbl_id&z.=1;
                    end;
			        else do;
                        Word_dv_&&Confidence_lbl_id&z.=0;
                    end;
					
                %end;
            end;
        run;
		proc sort data=&colpre.&m._all_stats_year;
            by &colyear %do z = 1 %to &npct.; descending Word_dv_&&Confidence_lbl_id&z. %end; descending _FREQ_ &col.;
        run;
	%end;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; &colpre.&m._out_t2a_stats %end;  ; quit; run;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; %do z=1 %to &npct.; &colpre.&m._out_t2a_excluded_&&Confidence_lbl_id&z. %end; %end; ; quit; run;

    %put ### Create individual tables based on the percentiles by year ###; %put; 
    %do m = 1 %to &ndsn.;
        %do z = 1 %to &npct.;  
	        proc sql noprint;
                create table 		&colpre.&m._year_&&Confidence_lbl_id&z. as
                select  			a.&colyear., a.&col., a._TYPE_, a._FREQ_
                from 				&colpre.&m._all_stats_year a
                where               Word_dv_&&Confidence_lbl_id&z.=0
                order by            a.&colyear., a.&col.;
            quit;
        %end;
    %end;

    %put ### Sort the datasets for merging and create summary statistics for the individual trimmed percentiles by year ###; %put;
    %do m = 1 %to &ndsn.; 
	    %do z = 1 %to &npct.;  
		    proc sort data=&colpre.&m._year_&&Confidence_lbl_id&z.;
	            by &colyear. &col.;
            run;
		    proc sql noprint;
		        create table &colpre.&m._stats_year_&&Confidence_lbl_id&z. as
                select       a.*, sum(a._FREQ_) as total
                from         &colpre.&m._year_&&Confidence_lbl_id&z. a;
            quit;
	        data &colpre.&m._stats_year_&&Confidence_lbl_id&z.;
                set &colpre.&m._stats_year_&&Confidence_lbl_id&z.;
			    total_percentage=_FREQ_ / total;
            run;
            proc sort data=&colpre.&m._stats_year_&&Confidence_lbl_id&z.;
                by &colyear. descending _TYPE_ &col.;
            run;
        %end;
    %end;	
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; %do z = 1 %to &npct.; &colpre.&m._year_&&Confidence_lbl_id&z. %end; %end; ; quit; run;

	%put ### Create a name variable for each *_all_stats and stats_*PCT tables by year ###; %put;
    %do m = 1 %to &ndsn.;
 	    data &colpre.&m._all_stats_year;
            set &colpre.&m._all_stats_year;
		    tempnum1= put(&m., z7.0);
	    run;
		data &colpre.&m._all_stats_year(drop=tempnum1-tempnum6);
			format id $30.;
            set &colpre.&m._all_stats_year;
	        tempnum2=compress(tempnum1,,"p");
	        tempnum3=compress(tempnum2,,"s"); 
            tempnum4=compress(tempnum3,,"t"); 
            tempnum5=compbl(tempnum4);
            tempnum6=trim(tempnum5);
            id=cats("&colpre.",tempnum6,"_all_stats");
        run;
	    %do z = 1 %to &npct.;  
	        data &colpre.&m._stats_year_&&Confidence_lbl_id&z.;
                set &colpre.&m._stats_year_&&Confidence_lbl_id&z.;
				tempnum1= put(&m., z7.0);
			run;
            data &colpre.&m._stats_year_&&Confidence_lbl_id&z.(drop=tempnum1-tempnum6);
			    format id $30.;
                set &colpre.&m._stats_year_&&Confidence_lbl_id&z.;
	            tempnum2=compress(tempnum1,,"p"); 
	            tempnum3=compress(tempnum2,,"s"); 
                tempnum4=compress(tempnum3,,"t"); 
                tempnum5=compbl(tempnum4);
                tempnum6=trim(tempnum5);
                id=cats("&colpre.",tempnum6,"_&&Confidence_lbl_id&z.");
            run;
        %end;
    %end;

    %put ### Get the grand totals by year for each individual dataset ###; %put;
    %do m = 1 %to &ndsn.; 
	    %do z = 1 %to &npct.;  
            proc sql noprint;
                create table 		&colpre.&m._stats_year_0_&&Confidence_lbl_id&z. as
                select  			unique a.id, a.&colyear., a.total
                from 				&colpre.&m._stats_year_&&Confidence_lbl_id&z. a
                order by            a.id;
            quit;
		    data &colpre.&m._stats_year_0_&&Confidence_lbl_id&z.(rename=(total=_FREQ_));
		        set &colpre.&m._stats_year_0_&&Confidence_lbl_id&z.;
            run; 
        %end;
    %end;

    %put ### Get the unique grand totals by year for each individual dataset ###; %put;
    %do m = 1 %to &ndsn.; 
	    %do z = 1 %to &npct.;
	        data &colpre.&m._stats_year_1_&&Confidence_lbl_id&z.;
                set &colpre.&m._stats_year_&&Confidence_lbl_id&z.;
			    if &col.="" then delete;
            run;
            proc sql noprint;
                create table 		&colpre.&m._stats_year_1_u_&&Confidence_lbl_id&z. as
                select  			unique a.id, a.&colyear., a.&col., count(a.&col.) as counts
                from 				&colpre.&m._stats_year_1_&&Confidence_lbl_id&z. a;
            quit;
		    proc sql noprint;
                create table 		&colpre.&m._stats_year_1_u2_&&Confidence_lbl_id&z. as
                select  			unique a.id, a.&colyear., a.counts
                from 				&colpre.&m._stats_year_1_u_&&Confidence_lbl_id&z. a;
            quit;
        %end;
    %end;
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; %do z = 1 %to &npct.; &colpre.&m._stats_year_1_&&Confidence_lbl_id&z. %end; %end; ; quit; run;
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; %do z = 1 %to &npct.; &colpre.&m._stats_year_1_u_&&Confidence_lbl_id&z. %end; %end; ; quit; run;

	%put ### Combine table *_stats_year_0 and *_stats_year_1_u2 ###; %put;
    %do m = 1 %to &ndsn.; 
	    %do z = 1 %to &npct.;
            proc sql noprint;
                create table 		&colpre.&m._stats_year_2_&&Confidence_lbl_id&z. as
                select  			a.id, a.&colyear., a._FREQ_, b.counts
                from 				&colpre.&m._stats_year_0_&&Confidence_lbl_id&z. a, &colpre.&m._stats_year_1_u2_&&Confidence_lbl_id&z. b
                where               a.id=b.id;
            quit;
        %end;
    %end;
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; %do z = 1 %to &npct.; &colpre.&m._stats_year_0_&&Confidence_lbl_id&z. %end; %end; ; quit; run;
	proc datasets lib=work nolist; delete %do m = 1 %to &ndsn.; %do z = 1 %to &npct.; &colpre.&m._stats_year_1_u2_&&Confidence_lbl_id&z. %end; %end; ; quit; run;

	%put ### Rename final datasets to expand number formatting in title, add analysis_level column, and concatenate _*_stats_year_*PCT and _*_stats_*PCT ###; %put;
    %do m = 1 %to &ndsn.;
        proc sql noprint;
            create table 		&colpre.&m._id_temp_year as
            select  			unique a.id
            from 				&colpre.&m._all_stats_year a;
        quit;
        data &colpre.&m._id_temp_year(drop=id);
	        format id1 $30.;
	        set &colpre.&m._id_temp_year;
		    id1=substr(id,1,find(id,"_",find(id,"&colpre.",1)+length("&colpre.")+1)-1);
	    run;
        data &colpre.&m._id_temp_year;
		    format id2 $8.;
		    set &colpre.&m._id_temp_year;
			id2=compress(id1,,"s");
		run;
		proc sql noprint;
            select   a.id2
            into     :temp_ds_name_year
            from     &colpre.&m._id_temp_year a;
        quit;
	    %do z = 1 %to &npct.;
            data &temp_ds_name_year._stats_year_&&Confidence_lbl_id&z.;
			    format analysis_level $9.;
	            set &colpre.&m._stats_year_&&Confidence_lbl_id&z.;
				analysis_level= "YEAR";
	        run;
        %end;
		data &temp_ds_name_year._stats0;
            set %do z = 1 %to &npct.; &temp_ds_name_year._stats_year_&&Confidence_lbl_id&z. &temp_ds_name_year._stats_&&Confidence_lbl_id&z.  %end; ;
        run;
        data &temp_ds_name_year._stats1(drop= _location id);
	       format _location 2. confidence_level $6.;
           set &temp_ds_name_year._stats0;
           _location = length(catt(id,"*")) - length(scan(catt(id,"*"),-1,"_"));
           confidence_level=substr(id,_location+1,length(id)-_location);
        run;
        proc sql noprint;
            create table 		&temp_ds_name_year._stats as
            select  			a.analysis_level, a.&colyear., a.confidence_level, a.&col., a._TYPE_, a._FREQ_, a.total, a.total_percentage
            from 				&temp_ds_name_year._stats1 a
            order by            a.analysis_level descending, a.&colyear., a.confidence_level , a._FREQ_ descending, a.&col.; 
        quit;
	    proc datasets lib=work nolist; delete &temp_ds_name_year._stats0 &temp_ds_name_year._stats1 ; quit; run;
	    proc datasets lib=work nolist; delete %do z=1 %to &npct.; &temp_ds_name_year._stats_&&Confidence_lbl_id&z.       %end; ; quit; run;
	    proc datasets lib=work nolist; delete %do z=1 %to &npct.; &temp_ds_name_year._stats_year_&&Confidence_lbl_id&z.  %end; ; quit; run;
    %end;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; %do z=1 %to &npct.; &colpre.&m._stats_year_&&Confidence_lbl_id&z. %end; %end; ; quit; run;

	 
	%put #####################################################################;
    %put 5.   Merge _*_all_stats and _*_all_stats_year;
    %put #####################################################################; %put;

    %do m = 1 %to &ndsn.;
	    data &colpre.&m._all_stats(rename=(%do z = 1 %to &npct.; Word_dv_&&Confidence_lbl_id&z.=Word_dv_agg_&&Confidence_lbl_id&z. %end;));
	        set &colpre.&m._all_stats;
        run; 
	    data &colpre.&m._all_stats_year(rename=(%do z = 1 %to &npct.; Word_dv_&&Confidence_lbl_id&z.=Word_dv_year_&&Confidence_lbl_id&z. %end;));
	        set &colpre.&m._all_stats_year;
        run; 
	    proc sql noprint;
            select   a.id2
            into     :temp_ds_name_comb
            from     &colpre.&m._id_temp_agg a;
        quit;
        proc sql noprint;
            create table 		&temp_ds_name_comb._dictionaries as
            select  			a.&colyear., a.&col., a._TYPE_, a._FREQ_, a.total_percentage
			                    %do z = 1 %to &npct.; ,a.Word_dv_year_&&Confidence_lbl_id&z. %end;
                                %do z = 1 %to &npct.; ,b.Word_dv_agg_&&Confidence_lbl_id&z.  %end;
            from 				&colpre.&m._all_stats_year a
	        full join           &colpre.&m._all_stats b
            on                  a.id=b.id
            and                 a.&colyear.=b.&colyear.
            and                 a.&col.=b.&col.;
        quit;
		proc sort data=&temp_ds_name_comb._dictionaries;
            by &colyear %do z = 1 %to &npct.; descending Word_dv_year_&&Confidence_lbl_id&z. %end; descending _FREQ_ &col.;
        run;
    %end;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.;  &colpre.&m._id_temp_agg &colpre.&m._all_stats %end; ; quit; run;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.;  &colpre.&m._id_temp_year &colpre.&m._all_stats_year %end; ; quit; run;
	proc datasets lib=work nolist; delete &temp_ds_name_agg._all_stats &temp_ds_name_year._all_stats_year ; quit; run;


	%put #####################################################################;
    %put 6A.  Create Global Summary tables (aggregate);
    %put #####################################################################; %put;

	%put ### Merge the percentile totals (aggregate) ###; %put;
	%do z = 1 %to &npct.;
        data global_totals0_agg_&&Confidence_lbl_id&z.(rename=(_FREQ_=grand_totals_agg_&&Confidence_lbl_id&z. counts=distinct_totals_agg_&&Confidence_lbl_id&z.));
            set %do m = 1 %to &ndsn.; &colpre.&m._stats_2_&&Confidence_lbl_id&z. %end; ;  
        run;
    %end;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; %do z=1 %to &npct.; &colpre.&m._stats_2_&&Confidence_lbl_id&z. %end; %end; ; quit; run;

	%put ### Add the global counts so that the score can be created for the percentiles ###; %put;
	%do z = 1 %to &npct.;
	    proc sql noprint;
            select   glob_grnd_totals_agg_&&Confidence_lbl_id&z., glob_dist_totals_agg_&&Confidence_lbl_id&z. 
            into     :global_g_totals_agg_&z., :global_d_totals_agg_&z.
            from     global_stats_2_&&Confidence_lbl_id&z.;
        quit;
        data global_totals0_agg_&&Confidence_lbl_id&z.;
	        set global_totals0_agg_&&Confidence_lbl_id&z.;
		    global_grnd_tot_agg_&&Confidence_lbl_id&z. = &&global_g_totals_agg_&z.;
            global_dist_tot_agg_&&Confidence_lbl_id&z. = &&global_d_totals_agg_&z.;
	    run;
    %end;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_stats_2_&&Confidence_lbl_id&z. %end; ; quit; run;

    %put ### Create the scores and reorder the columns ###; %put;
	%do z = 1 %to &npct.;
	    proc sort data=global_totals0_agg_&&Confidence_lbl_id&z.;
            by id;
        run;
        data global_totals0_agg_&&Confidence_lbl_id&z.;
	        format grnd_tot_score_agg_&&Confidence_lbl_id&z. 10.8 dist_tot_score_agg_&&Confidence_lbl_id&z. 10.8;
	        set global_totals0_agg_&&Confidence_lbl_id&z.;
		    grnd_tot_score_agg_&&Confidence_lbl_id&z. = grand_totals_agg_&&Confidence_lbl_id&z./global_grnd_tot_agg_&&Confidence_lbl_id&z.;
            dist_tot_score_agg_&&Confidence_lbl_id&z. = distinct_totals_agg_&&Confidence_lbl_id&z./global_dist_tot_agg_&&Confidence_lbl_id&z.;
	    run;
        proc sql noprint;
            create table 		global_totals1_agg_&&Confidence_lbl_id&z. as
            select  			a.id, 
                                a.grand_totals_agg_&&Confidence_lbl_id&z., a.global_grnd_tot_agg_&&Confidence_lbl_id&z., a.grnd_tot_score_agg_&&Confidence_lbl_id&z., 
                                a.distinct_totals_agg_&&Confidence_lbl_id&z., a.global_dist_tot_agg_&&Confidence_lbl_id&z., a.dist_tot_score_agg_&&Confidence_lbl_id&z.
            from 				global_totals0_agg_&&Confidence_lbl_id&z. a
            order by            a.id;
        quit;
    %end;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_totals0_agg_&&Confidence_lbl_id&z. %end; ; quit; run;


	%put #####################################################################;
    %put 6B.  Create Global Summary tables (year-level);
    %put #####################################################################; %put;

	%put ### Merge the percentile totals (year-level) ###; %put;
	%do z = 1 %to &npct.;
        data global_totals0_year_&&Confidence_lbl_id&z.(rename=(_FREQ_=grand_totals_year_&&Confidence_lbl_id&z. counts=distinct_totals_year_&&Confidence_lbl_id&z.));
            set %do m = 1 %to &ndsn.; &colpre.&m._stats_year_2_&&Confidence_lbl_id&z. %end; ;  
        run;
    %end;
	proc datasets lib=work nolist; delete %do m=1 %to &ndsn.; %do z=1 %to &npct.; &colpre.&m._stats_year_2_&&Confidence_lbl_id&z. %end; %end; ;quit; run;

	%put ### Add the global counts so that the score can be created for the percentiles ###; %put;
	%do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_totals1_year_&&Confidence_lbl_id&z. as
            select  			a.*,b.*
            from 				global_totals0_year_&&Confidence_lbl_id&z. a
	        left join           global_stats_year_2_&&Confidence_lbl_id&z. b
            on                  a.&colyear.=b.&colyear.;
        quit;
        data global_totals1_year_&&Confidence_lbl_id&z.(rename=(glob_grnd_totals_year_&&Confidence_lbl_id&z.=global_grnd_tot_year_&&Confidence_lbl_id&z. glob_dist_totals_year_&&Confidence_lbl_id&z=global_dist_tot_year_&&Confidence_lbl_id&z.));
            set global_totals1_year_&&Confidence_lbl_id&z.;  
        run;
		data global_totals0_year_&&Confidence_lbl_id&z.;
            set global_totals1_year_&&Confidence_lbl_id&z.;  
        run;
    %end;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_stats_year_2_&&Confidence_lbl_id&z. %end; ; quit; run;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_totals1_year_&&Confidence_lbl_id&z. %end; ; quit; run;

    %put ### Create the scores and reorder the columns ###; %put;
	%do z = 1 %to &npct.;
	    proc sort data=global_totals0_year_&&Confidence_lbl_id&z.;
            by id;
        run;
        data global_totals0_year_&&Confidence_lbl_id&z.;
	        format grnd_tot_score_year_&&Confidence_lbl_id&z. 10.8 dist_tot_score_year_&&Confidence_lbl_id&z. 10.8;
	        set global_totals0_year_&&Confidence_lbl_id&z.;
		    grnd_tot_score_year_&&Confidence_lbl_id&z. = grand_totals_year_&&Confidence_lbl_id&z./global_grnd_tot_year_&&Confidence_lbl_id&z.;
            dist_tot_score_year_&&Confidence_lbl_id&z. = distinct_totals_year_&&Confidence_lbl_id&z./global_dist_tot_year_&&Confidence_lbl_id&z.;
	    run;
        proc sql noprint;
            create table 		global_totals1_year_&&Confidence_lbl_id&z. as
            select  			a.id, 
                                a.grand_totals_year_&&Confidence_lbl_id&z., a.global_grnd_tot_year_&&Confidence_lbl_id&z., a.grnd_tot_score_year_&&Confidence_lbl_id&z., 
                                a.distinct_totals_year_&&Confidence_lbl_id&z., a.global_dist_tot_year_&&Confidence_lbl_id&z., a.dist_tot_score_year_&&Confidence_lbl_id&z.
            from 				global_totals0_year_&&Confidence_lbl_id&z. a
            order by            a.id;
        quit;
    %end;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_totals0_year_&&Confidence_lbl_id&z. %end; ; quit; run;
 
	
	%put #####################################################################;
    %put 7.   Combine Aggregate and Year-level Global Summary tables;
    %put #####################################################################; %put;

	%do z = 1 %to &npct.;
        proc sql noprint;
            create table 		global_totals1_&&Confidence_lbl_id&z. as
            select  			a.*,b.*
            from 				global_totals1_agg_&&Confidence_lbl_id&z. a, global_totals1_year_&&Confidence_lbl_id&z. b
            where               a.id=b.id;
        quit;
    %end;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_totals1_agg_&&Confidence_lbl_id&z.  %end; ; quit; run;
 	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_totals1_year_&&Confidence_lbl_id&z. %end; ; quit; run;

	%put ### Create summary statistics ###; %put;
	%do z = 1 %to &npct.;
        proc means data=global_totals1_&&Confidence_lbl_id&z. noprint;
	        var grand_totals_agg_&&Confidence_lbl_id&z. distinct_totals_agg_&&Confidence_lbl_id&z. 
                grnd_tot_score_agg_&&Confidence_lbl_id&z.  dist_tot_score_agg_&&Confidence_lbl_id&z.
                grand_totals_year_&&Confidence_lbl_id&z. distinct_totals_year_&&Confidence_lbl_id&z. 
                grnd_tot_score_year_&&Confidence_lbl_id&z.  dist_tot_score_year_&&Confidence_lbl_id&z.;
            output out=global_sumstats_&&Confidence_lbl_id&z.;
        run;
    %end;

	%put ### Create a temp id variable so the tables can be joined ###; %put;
    %do z = 1 %to &npct.;
        data global_totals_&&Confidence_lbl_id&z.(drop=id);
	        format id1 $30.;
	        set global_totals1_&&Confidence_lbl_id&z.;
		    id1=substr(id,1,find(id,"_",find(id,"&colpre.",1)+length("&colpre.")+1)-1);
	    run;
		data global_totals_&&Confidence_lbl_id&z.(rename=(id1=id));
	        set global_totals_&&Confidence_lbl_id&z.;
	    run;
	%end;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_totals1_&&Confidence_lbl_id&z. %end; ; quit; run;

    %put ### Merge the tables with the scores (Cannot do in loop) ###; %put;
    proc sql noprint;
        create table 		global_totals0 as
        select  			a.id,b.*
        from 				&inputds. a
		full join           global_totals_990pct b
		on                  a.id=b.id;
    quit;
    proc sql noprint;
        create table 		global_totals1 as
        select  			a.*,b.*
        from 				global_totals0 a
		full join           global_totals_950pct b
		on                  a.id=b.id;
    quit;
    proc sql noprint;
        create table 		global_totals as
        select  			a.*,b.*
        from 				global_totals1 a
		full join           global_totals_900pct b
		on                  a.id=b.id;
    quit;
    proc datasets lib=work nolist; delete global_totals0 global_totals1 ; quit; run;
	proc datasets lib=work nolist; delete %do z=1 %to &npct.; global_totals_&&Confidence_lbl_id&z. %end; ; quit; run;

    %put ### Merge the output from the macro with the dataset ###; %put;
    proc sql noprint;
        create table 		&outputds. as
        select  			a.*,b.*
        from 				&inputds. a
	    full join           global_totals b
        on                  a.id=b.id;
    quit;

%mend split;


*Call the macro Split that splits the descriptions into single datasets;
%split(npct=&Percentile_nobs.,colpre=&columntitle.,colyear=&columnyear.,inputds=&inputdataset.,outputds=&outputdataset.,col=&paragraphcol.);




*=====================================================================;
*Sign off if using SAS/Connect to WRDS;
*=====================================================================; 

*x 'rmdir /sastemp5/mydata';
*signoff;



*TODO:;
    *Look up similarity measures;
    *Rework the word_dv section base on A1 of Hoberg and Phillips (2007)
    *Implement similarity measures;
	*Fix paraparse and update column so that algorithm will work.
    *Create betweenparse macro;
    *Find out why output is only 62 columns (fixed????);


