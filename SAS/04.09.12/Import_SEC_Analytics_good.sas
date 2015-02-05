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
*%include "C:\Users\bdaughdr\Dropbox\Research\SAS\Macros\Brad\DeleteMacros.sas"; *Office;
%include "\\tsclient\C\Users\bdaughdr\Dropbox\Research\SAS\Macros\Brad\DeleteMacros.sas"; *CoralSea from Office;
*%include "\\tsclient\C\Users\S. Brad Daughdrill\Documents\My Dropbox\Research\SAS\Macros\Brad\DeleteMacros.sas";  *CoralSea from Home;
*=====================================================================;
*Delete Macro Variables;
*=====================================================================;
%DeleteMacros;
*=====================================================================;
*Create Macro Directory;
*=====================================================================;
%global fullmacrodirectory;
*%let fullmacrodirectory=C:\Users\bdaughdr\Dropbox\Research\SAS\Macros; *Office;
%let fullmacrodirectory=\\tsclient\C\Users\bdaughdr\Dropbox\Research\SAS\Macros; *CoralSea from Office;
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
endrsubmit;
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

*/

/*
rsubmit;
%let my_exhibits_yrstrt = 2007;			
%let my_exhibits_yrend = 2008;
%let my_exhibits_vars = GVKEY CIK FDATE FORM CONAME FNAME FSIZE RDATE SECADATE SECATIME SEQUENCE TYPE DESCRIPTION FILENAME;
data my_exhibits(keep = &my_exhibits_vars.);	
	set wrdssec.exhibits;
	*where year(fdate) between (&my_exhibits_yrstrt.-1) and (&my_exhibits_yrend.+1); 
	where year(fdate) between (&my_exhibits_yrstrt.) and (&my_exhibits_yrend.); 
run;
proc download data=my_exhibits out=my_exhibits; run;
endrsubmit;

*Find filings that aren't 10-k's;
rsubmit;
data my_exhibits_not_10k;	
	set my_exhibits;
	where form not like '%10%K%';
run;
proc download data=my_exhibits_not_10k out=my_exhibits_not_10k; run;
endrsubmit;

*Remove filings that aren't 10-k's;
rsubmit;
data my_exhibits_10k_raw(drop=tempurl tempurl2);	
	set my_exhibits;
	where form like '%10%K%';
	format local_url_htm $100. local_url_txt $100. web_url_htm $100. web_url_txt $100.;
	fyear = year(fdate);
	local_url_txt = cats("/wrds/sec/archives/",FNAME);
	web_url_txt = cats("http://www.sec.gov/Archives/",FNAME);
	tempurl = substr(FNAME,1,find(FNAME,".txt",1)-1);
	tempurl2 = compress(tempurl,'- ');
	local_url_htm = cats("/wrds/sec/archives/",tempurl,"-index.htm");
	web_url_htm = cats("http://www.sec.gov/Archives/",tempurl2,"/",FILENAME);
	cik_short = substr(FNAME,find(FNAME,"data/",1)+5,find(FNAME,"/",find(FNAME,"data/",1)+5)-find(FNAME,"data/",1)-5);
	label fyear="year"
          local_url_txt="local URL to text file"
          web_url_txt="web URL to text file"
          local_url_htm="local URL to htm file"
          web_url_htm="web URL to htm file"
          cik_short="cik_short";
run;
proc download data=my_exhibits_10k_raw out=my_exhibits_10k_raw; run;
endrsubmit;

*Find exhibits, graphics, etc;
rsubmit;
data my_exhibits_10k_extra;	
	set my_exhibits_10k_raw;
	where type not like '%10%K%';
run;
proc download data=my_exhibits_10k_extra out=my_exhibits_10k_extra; run;
endrsubmit;

*Remove exhibits, graphics, etc;
rsubmit;
data my_exhibits_10k_only;	
	set my_exhibits_10k_raw;
	where type like '%10%K%';
run;
proc download data=my_exhibits_10k_only out=my_exhibits_10k_only; run;
endrsubmit;


*Find the NT 10-K's;
rsubmit;
data my_exhibits_nt10k;	
	set my_exhibits_10k_only;
	where type not like '10%K%';
run;
proc download data=my_exhibits_nt10k out=my_exhibits_nt10k; run;
endrsubmit;

*Remove the NT 10-K's;
rsubmit;
data my_exhibits_10k_good;	
	set my_exhibits_10k_only;
	where type like '10%K%';
run;
proc download data=my_exhibits_10k_good out=my_exhibits_10k_good; run;
endrsubmit;

rsubmit;
data my_exhibits_10k_good2;	
	set my_exhibits_10k_good;
	where type not like '%PDF%';
run;
proc download data=my_exhibits_10k_good2 out=my_exhibits_10k_good2; run;
endrsubmit;

rsubmit;
proc sort data=my_exhibits_10k_good2;
by cik fyear;
run;
proc sql;
	create table 		my_exhibits_10k_final as
	select  			a.*, count(a.cik) as yearly_filing_count_total
	from 				my_exhibits_10k_good2 a
	group by 			a.cik, a.fyear
	order by			a.cik, a.fyear;
quit;
data my_exhibits_10k_final;	
	set my_exhibits_10k_final;
	by cik fyear;
	if first.fyear then yearly_filing_count=0;
	yearly_filing_count+1;
	*if last.fyear then output;
run;
proc download data=my_exhibits_10k_final out=my_exhibits_10k_final; run;
endrsubmit;

data my_exhibits_10k_final_backup;	
	set my_exhibits_10k_final;
run;



*Print last downloaded data;
proc print data=&syslast(obs=100); 
  by CIK;
  id fyear;
  var coname web_url_htm;
run;

*select top 20;
proc sql outobs=20;
	create table 	my_exhibits_10k_final_20 as 
	select 			a.*
	from 			my_exhibits_10k_final as a;
quit;
*/

*=====================================================================;
*Product Description Macro;
*=====================================================================; 
options symbolgen spool mlogic mprint;
%include "&projectrootdirectory.\SAS\lineparse.sas";
%include "&projectrootdirectory.\SAS\textparse.sas";
%include "&projectrootdirectory.\SAS\paraparse.sas";
%include "&projectrootdirectory.\SAS\lineparaparse.sas";

rsubmit;
filename rfile1 "lineparse.sas";
proc upload infile="H:\Research\Web_Crawler\SAS\lineparse.sas" outfile=rfile1;
run;
filename rfile2 "textparse.sas";
proc upload infile="H:\Research\Web_Crawler\SAS\textparse.sas" outfile=rfile2;
run;
filename rfile3 "paraparse.sas";
proc upload infile="H:\Research\Web_Crawler\SAS\paraparse.sas" outfile=rfile3;
run;
filename rfile4 "lineparaparse.sas";
proc upload infile="H:\Research\Web_Crawler\SAS\lineparaparse.sas" outfile=rfile4;
run;

%include "lineparse.sas";
%include "textparse.sas";
%include "paraparse.sas";
%include "lineparaparse.sas";
endrsubmit;

rsubmit;

%let string=Item 2.;
%LINEPARSE(INSET=my_exhibits_10k_final,OUTSET=lineparse_output,FNAME_FULL=local_url_txt,TSTR=&string.);

proc download data=lineparse_output out=lineparse_output;
run;

endrsubmit;

rsubmit;

%let string=Item 2.;
%let num=300;
%TEXTPARSE(INSET=my_exhibits_10k_final,OUTSET=textparse_output,FNAME_FULL=local_url_txt,TSTR=&string.,ln=&num.);

proc download data=textparse_output out=textparse_output;
run;

endrsubmit;


rsubmit;

%let string=Item 2.;
%let num2=20;
%PARAPARSE(INSET=my_exhibits_10k_final,OUTSET=paraparse_output,FNAME_FULL=local_url_txt,TSTR=&string.,NLINE=&num2.);

proc download data=paraparse_output out=paraparse_output;
run;

endrsubmit;


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
data textparse_match(drop=Match_Text Match_Text_compress1-Match_Text_compress3 Match_Text_compbl Match_Text_trim);
    set textparse_match;
    Match_Text_compress1=compress(Match_Text,,"p");  *Compressing punctuation characters;
    Match_Text_compress2=compress(Match_Text_compress1,"+-","d");  *Compressing digits and plus/minus signs characters;
    Match_Text_compress3=compress(Match_Text_compress2,,"c");  *Compressing control characters;
    Match_Text_compbl=compbl(Match_Text_compress3);
    Match_Text_trim=trim(Match_Text_compbl);
    Match_Text_upcase = upcase(Match_Text_trim);
run;
proc download data=textparse_match out=textparse_match;
run;
data textparse_match(rename=(Match_Text_upcase=Match_Text));
    set textparse_match;
    if Match_Text_upcase="" then delete;
run;
proc download data=textparse_match out=textparse_match;
run;
endrsubmit;

*Replace SAS words that break macro;
data textparse_match_final(drop=ob);
    format id $30.;
    set textparse_match;
	Match_Text = tranwrd(Match_Text,'AND','_AND');
	Match_Text = tranwrd(Match_Text,'OR','_OR');
	Match_Text = tranwrd(Match_Text,'NOT','_NOT');
	Match_Text = tranwrd(Match_Text,'IN','_IN');
	Match_Text = tranwrd(Match_Text,'ON','_ON');
	Match_Text = tranwrd(Match_Text,'BETWEEN','_BETWEEN');
	ob=_N_;
	id=cats("dsn",ob);
run;


*Drop all columns except for the one with the desired text;
data textparse_match_trim(keep= Match_Text);
    set textparse_match_final;
run;

*Determine number of observations;
data _null_;
	set textparse_match_trim end=last;
	*call symputx("Match_Textid"||left(put(_n_,4.)), trim(left(Match_Text)),L);
	call symput ("nobsid", _n_); * keep overwriting value until end = total obs.;
run;

*=====================================================================;
*Split Macros;
*=====================================================================;

*options mprint symbolgen mlogic spool;
options nomprint nosymbolgen nomlogic;

*define the macro Explode;
%macro explode(text=,dataset=,delim=,arrayref=);
    %put ; %put ### START. Explode Macro on <&dataset.> in column <&text.>;
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
        select   count(*) into: nObs_explode
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

*define the macro Split;
%macro split(ndsn=,ds=,col=); 
    %put ; %put ### START. Split Macro;
    data %do j = 1 %to &ndsn.; dsn&j. %end; ; 
        retain numlines; 
        set &ds. nobs=nobs; 
        if _n_ eq 1 
            then do; 
                if mod(nobs,&ndsn.) eq 0 then numlines=int(nobs/&ndsn.); 
                else numlines=int(nobs/&ndsn.)+1; 
            end; 
        if _n_ le numlines then output dsn1; 
            %do j = 2 %to &ndsn.; 
                else if _n_ le (&j.*numlines)  then output dsn&j.; 
            %end; 
    run; 
	%do m = 1 %to &ndsn.; 
        data dsn&m.(drop=numlines);
            set dsn&m.;
        run;
    %end;
	
    *explode descriptions and delete temporary datasets;
    %do l = 1 %to &ndsn.; 
        %explode(text=&col., dataset=dsn&l., delim=%str( ), arrayRef=y&l.);
    %end;
   proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i. %end;  ; quit; run;  
    *transpose descriptions and delete temporary datasets;
    %do m = 1 %to &ndsn.; 
        proc transpose data=dsn&m._out out=dsn&m._out_t;
            var _ALL_;
        run;
        data dsn&m._out_t(drop=_Name_ _Label_);
            set dsn&m._out_t(rename=(COL1=&col.));
	        if _N_=1 then delete;
        run;
        data dsn&m._out_t;
            set dsn&m._out_t;
	        &col. = compress(&col.,'_');
        run;
    %end;
    proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._out %end;  ; quit; run; 
    *sort the datasets for merging and create summary statistics;
    %do m = 1 %to &ndsn.; 
	    proc sort data=dsn&m._out_t;
	        by &col.;
        run;
	    proc means data=dsn&m._out_t noprint;
	        class &col.;
            output out=dsn&m._out_t_stats;
        run;
		proc sql noprint;
            select   _FREQ_ into: total_words_&m.
            from     dsn&m._out_t_stats
			where    _TYPE_=0;
        quit;
	    data dsn&m._out_t_stats;
            set dsn&m._out_t_stats;
			total_percentage=_FREQ_ / &&total_words_&m.;
        run;
        proc sort data=dsn&m._out_t_stats;
            by descending _FREQ_ &col.;
        run;
    %end;
    *create global dictionary and delete temporary datasets;
    data dsn_global;
        set %do m = 1 %to &ndsn.; dsn&m._out_t %end; ;  
    run;
    proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._out_t %end;  ; quit; run; 
    *Save global dictionary to test directories;
	data &testdatalibrary..dsn_global;
        set dsn_global;
    run;
    data &emdatalibrary..dsn_global;
        set dsn_global;
    run;
	*Compute summary statistics for global dictionary;
	proc means data=dsn_global noprint;
		class &col.;
		output out=dsn_global_stats;
	run;
    proc sql noprint;
        select   _FREQ_ into: global_total_words
        from     dsn_global_stats
		where    _TYPE_=0;
    quit;
	data dsn_global_stats;
        set dsn_global_stats;
        total_percentage=_FREQ_ / &global_total_words.;
    run;
	proc sort data=dsn_global_stats;
	    by descending _FREQ_ &col.;
    run;
	proc datasets lib=work nolist; delete dsn_global ; quit; run;
    *find the top x% entries;
    proc sql noprint;
        select   count(&col.) into: global_distinct_words
        from     dsn_global_stats
        where    _TYPE_=1;
    quit;
	data dsn_global_stats;
        set dsn_global_stats;
        word_01pct_cutoff=ceil(.01*&global_distinct_words.);
        word_05pct_cutoff=ceil(.05*&global_distinct_words.);
        word_10pct_cutoff=ceil(.10*&global_distinct_words.);
		obnum=_N_;
		obnumminus1=obnum-1;
    run;
	data dsn_global_stats(drop=word_01pct_cutoff word_05pct_cutoff word_10pct_cutoff obnum obnumminus1);
        set dsn_global_stats;
        if _TYPE_=0 then do;
		    word_01pct_dv = -1;
            word_05pct_dv = -1;
            word_10pct_dv = -1;
        end;
		else if _TYPE_=1 then do;
            if obnumminus1<=word_01pct_cutoff then do;
			    word_01pct_dv = 1;
		    end;
		    else do;
		        word_01pct_dv = 0;
            end;
		    if obnumminus1<=word_05pct_cutoff then do;
		        word_05pct_dv = 1;
		    end;
		    else do;
		        word_05pct_dv = 0;
            end;
		    if obnumminus1<=word_10pct_cutoff then do;
		        word_10pct_dv = 1;
		    end;
		    else do;
		        word_10pct_dv = 0;
            end;
        end;
    run; 
    proc sort data=dsn_global_stats;
        by descending word_01pct_dv descending word_05pct_dv descending word_10pct_dv descending _FREQ_ &col.;
    run;
	*Create individual dicitonary for the most commonly used 1% of words;
    proc sql noprint;
        create table 		dsn_global_01pct_list as
        select  			a.&col.
        from 				dsn_global_stats a
        where               word_01pct_dv=1
        order by            a.&col.;
    quit;
    data _null_;
	     set dsn_global_01pct_list end=last;
	     call symputx("descrip_01pct"||left(put(_n_,4.)), trim(left(&col.)),L);
	     call symput ("nobsid_01pct", _n_); * keep overwriting value until end = total obs.;
    run;
	*Create individual dicitonary for the most commonly used 5% of words;
	proc sql noprint;
        create table 		dsn_global_05pct_list as
        select  			a.&col.
        from 				dsn_global_stats a
        where               word_05pct_dv=1
        order by            a.&col.;
    quit;
	data _null_;
	     set dsn_global_05pct_list end=last;
	     call symputx("descrip_05pct"||left(put(_n_,4.)), trim(left(&col.)),L);
	     call symput ("nobsid_05pct", _n_); * keep overwriting value until end = total obs.;
    run;
	*Create individual dicitonary for the most commonly used 10% of words;
	proc sql noprint;
        create table 		dsn_global_10pct_list as
        select  			a.&col.
        from 				dsn_global_stats a
        where               word_10pct_dv=1
        order by            a.&col.;
    quit;
	data _null_;
	     set dsn_global_10pct_list end=last;
	     call symputx("descrip_10pct"||left(put(_n_,4.)), trim(left(&col.)),L);
	     call symput ("nobsid_10pct", _n_); * keep overwriting value until end = total obs.;
    run;
    *Create global tables based on the percentiles;
    proc sql noprint;
        create table 		dsn_global_01pct as
        select  			a.&col., a._TYPE_, a._FREQ_
        from 				dsn_global_stats a
        where               word_01pct_dv=0
        order by            a.&col.;
    quit;
	proc sql noprint;
        create table 		dsn_global_05pct as
        select  			a.&col., a._TYPE_, a._FREQ_
        from 				dsn_global_stats a
        where               word_05pct_dv=0
        order by            a.&col.;
    quit;
	proc sql noprint;
        create table 		dsn_global_10pct as
        select  			a.&col., a._TYPE_, a._FREQ_
        from 				dsn_global_stats a
        where               word_10pct_dv=0
        order by            a.&col.;
    quit;
    *sort the datasets for merging and create summary statistics for the global trimmed 1 percentile;
    proc sort data=dsn_global_01pct;
	    by &col.;
    run;
    proc sql noprint;
        create table dsn_global_01pct_stats as
        select       a.*, sum(_FREQ_) as total
        from         dsn_global_01pct a;
    quit;
    data dsn_global_01pct_stats;
        set dsn_global_01pct_stats;
        total_percentage=_FREQ_ / total;
    run;
    proc sort data=dsn_global_01pct_stats;
        by descending _TYPE_ &col.;
    run;
    *sort the datasets for merging and create summary statistics for the global trimmed 5 percentile;
    proc sort data=dsn_global_05pct;
	    by &col.;
    run;
    proc sql noprint;
        create table dsn_global_05pct_stats as
        select       a.*, sum(_FREQ_) as total
        from         dsn_global_05pct a;
    quit;
    data dsn_global_05pct_stats;
        set dsn_global_05pct_stats;
        total_percentage=_FREQ_ / total;
    run;
    proc sort data=dsn_global_05pct_stats;
        by descending _TYPE_ &col.;
    run;
    *sort the datasets for merging and create summary statistics for the global trimmed 10 percentile;
    proc sort data=dsn_global_10pct;
	    by &col.;
    run;
    proc sql noprint;
        create table dsn_global_10pct_stats as
        select       a.*, sum(_FREQ_) as total
        from         dsn_global_10pct a;
    quit;
    data dsn_global_10pct_stats;
        set dsn_global_10pct_stats;
        total_percentage=_FREQ_ / total;
    run;
    proc sort data=dsn_global_10pct_stats;
        by descending _TYPE_ &col.;
    run;
	proc datasets lib=work nolist; delete dsn_global_01pct dsn_global_05pct dsn_global_10pct ; quit; run;
    *Get the grand totals for global dataset;
    proc sql noprint;
        create table 		dsn_global_01pct_stats_0 as
        select  			unique a.total
        from 				dsn_global_01pct_stats a;
    quit;
    data dsn_global_01pct_stats_0(rename=(total=_FREQ_));
		set dsn_global_01pct_stats_0;
    run; 
    proc sql noprint;
        create table 		dsn_global_05pct_stats_0 as
        select  			unique a.total
        from 				dsn_global_05pct_stats a;
    quit;
    data dsn_global_05pct_stats_0(rename=(total=_FREQ_));
		set dsn_global_05pct_stats_0;
    run; 
    proc sql noprint;
        create table 		dsn_global_10pct_stats_0 as
        select  			unique a.total
        from 				dsn_global_10pct_stats a;
    quit;
    data dsn_global_10pct_stats_0(rename=(total=_FREQ_));
		set dsn_global_10pct_stats_0;
    run; 
    *Get the unique grand totals for each individual dataset; 
	data dsn_global_01pct_stats_1;
        set dsn_global_01pct_stats;
        if &col.="" then delete;
    run;
    proc sql noprint;
        create table 		dsn_global_01pct_stats_1_u as
        select  			unique a.&col., count(a.&col.) as counts
        from 				dsn_global_01pct_stats_1 a;
    quit;
	proc sql noprint;
        create table 		dsn_global_01pct_stats_1_u2 as
        select  			unique a.counts
        from 				dsn_global_01pct_stats_1_u a;
    quit;   
    data dsn_global_05pct_stats_1;
        set dsn_global_05pct_stats;
        if &col.="" then delete;
    run;
    proc sql noprint;
        create table 		dsn_global_05pct_stats_1_u as
        select  			unique a.&col., count(a.&col.) as counts
        from 				dsn_global_05pct_stats_1 a;
    quit;
	proc sql noprint;
        create table 		dsn_global_05pct_stats_1_u2 as
        select  			unique a.counts
        from 				dsn_global_05pct_stats_1_u a;
    quit;
    data dsn_global_10pct_stats_1;
        set dsn_global_10pct_stats;
        if &col.="" then delete;
    run;
    proc sql noprint;
        create table 		dsn_global_10pct_stats_1_u as
        select  			unique a.&col., count(a.&col.) as counts
        from 				dsn_global_10pct_stats_1 a;
    quit;
	proc sql noprint;
        create table 		dsn_global_10pct_stats_1_u2 as
        select  			unique a.counts
        from 				dsn_global_10pct_stats_1_u a;
    quit;
	proc datasets lib=work nolist; delete dsn_global_01pct_stats_1 dsn_global_05pct_stats_1 dsn_global_10pct_stats_1 ; quit; run;
	proc datasets lib=work nolist; delete dsn_global_01pct_stats_1_u dsn_global_05pct_stats_1_u dsn_global_10pct_stats_1_u ; quit; run;
    *Combine global table *_stats_0 and *_stats_1_u2;
    proc sql noprint;
        create table 		dsn_global_01pct_stats_2 as
        select  			a._FREQ_, b.counts
        from 				dsn_global_01pct_stats_0 a, dsn_global_01pct_stats_1_u2 b;
    quit;
	proc sql noprint;
        create table 		dsn_global_05pct_stats_2 as
        select  			a._FREQ_, b.counts
        from 				dsn_global_05pct_stats_0 a, dsn_global_05pct_stats_1_u2 b;
    quit;
	proc sql noprint;
        create table 		dsn_global_10pct_stats_2 as
        select  			a._FREQ_, b.counts
        from 				dsn_global_10pct_stats_0 a, dsn_global_10pct_stats_1_u2 b;
    quit;
    data dsn_global_01pct_stats_2(rename=(_FREQ_=global_grand_totals_01 counts=global_distinct_totals_01));
        set dsn_global_01pct_stats_2;  
    run;
	data dsn_global_05pct_stats_2(rename=(_FREQ_=global_grand_totals_05 counts=global_distinct_totals_05));
        set dsn_global_05pct_stats_2;  
    run;
	data dsn_global_10pct_stats_2(rename=(_FREQ_=global_grand_totals_10 counts=global_distinct_totals_10));
        set dsn_global_10pct_stats_2;  
    run;
	proc datasets lib=work nolist; delete dsn_global_01pct_stats_0 dsn_global_05pct_stats_0 dsn_global_10pct_stats_0 ; quit; run;
	proc datasets lib=work nolist; delete dsn_global_01pct_stats_1_u2 dsn_global_05pct_stats_1_u2 dsn_global_10pct_stats_1_u2 ; quit; run;
	*Add common word flags;
	%do m = 1 %to &ndsn.;
	    data dsn&m._all_stats;
            set dsn&m._out_t_stats;
            if _TYPE_=0 then do;
		        word_01pct_dv = -1;
                word_05pct_dv = -1;
                word_10pct_dv = -1;
            end;
		    else if _TYPE_=1 then do;
			    if &col. in ( %do i = 1 %to &nobsid_01pct.; "&&descrip_01pct&i"    %end;  ) then do;
                    word_01pct_dv=1;
                end;
			    else do;
                    word_01pct_dv=0;
                end;
			    if &col. in ( %do i = 1 %to &nobsid_05pct.; "&&descrip_05pct&i"    %end;  ) then do;
                    word_05pct_dv=1;
                end;
			    else do;
                    word_05pct_dv=0;
                end;
			    if &col. in ( %do i = 1 %to &nobsid_10pct.; "&&descrip_10pct&i"    %end;  ) then do;
                    word_10pct_dv=1;
                end;
			    else do;
                    word_10pct_dv=0;
                end;
            end;
        run;
        proc sort data=dsn&m._all_stats;
            by descending word_01pct_dv descending word_05pct_dv descending word_10pct_dv descending _FREQ_ &col.;
        run;
	%end;
	proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._out_t_stats %end;  ; quit; run;
    *Create individual tables based on the percentiles;
    %do m = 1 %to &ndsn.; 
	    proc sql noprint;
            create table 		dsn&m._01pct as
            select  			a.&col., a._TYPE_, a._FREQ_
            from 				dsn&m._all_stats a
            where               word_01pct_dv=0
            order by            a.&col.;
        quit;
	    proc sql noprint;
            create table 		dsn&m._05pct as
            select  			a.&col., a._TYPE_, a._FREQ_
            from 				dsn&m._all_stats a
            where               word_05pct_dv=0
            order by            a.&col.;
        quit;
	    proc sql noprint;
            create table 		dsn&m._10pct as
            select  			a.&col., a._TYPE_, a._FREQ_
            from 				dsn&m._all_stats a
            where               word_10pct_dv=0
            order by            a.&col.;
        quit;
    %end;
	*sort the datasets for merging and create summary statistics for the individual trimmed 1 percentile;
    %do m = 1 %to &ndsn.; 
	    proc sort data=dsn&m._01pct;
	        by &col.;
        run;
		proc sql noprint;
		    create table dsn&m._01pct_stats as
            select       a.*, sum(_FREQ_) as total
            from         dsn&m._01pct a;
        quit;
 
	    data dsn&m._01pct_stats;
            set dsn&m._01pct_stats;
			total_percentage=_FREQ_ / total;
        run;
        proc sort data=dsn&m._01pct_stats;
            by descending _TYPE_ &col.;
        run;
    %end;	
	*sort the datasets for merging and create summary statistics for the individual trimmed 5 percentile;
    %do m = 1 %to &ndsn.; 
	    proc sort data=dsn&m._05pct;
	        by &col.;
        run;
		proc sql noprint;
		    create table dsn&m._05pct_stats as
            select       a.*, sum(_FREQ_) as total
            from         dsn&m._05pct a;
        quit;
 
	    data dsn&m._05pct_stats;
            set dsn&m._05pct_stats;
			total_percentage=_FREQ_ / total;
        run;
        proc sort data=dsn&m._05pct_stats;
            by descending _TYPE_ &col.;
        run;
    %end;
    *sort the datasets for merging and create summary statistics for the individual trimmed 10 percentile;
    %do m = 1 %to &ndsn.; 
	    proc sort data=dsn&m._10pct;
	        by &col.;
        run;
		proc sql noprint;
		    create table dsn&m._10pct_stats as
            select       a.*, sum(_FREQ_) as total
            from         dsn&m._10pct a;
        quit;
 
	    data dsn&m._10pct_stats;
            set dsn&m._10pct_stats;
			total_percentage=_FREQ_ / total;
        run;
        proc sort data=dsn&m._10pct_stats;
            by descending _TYPE_ &col.;
        run;
    %end;
	proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._01pct dsn&i._05pct dsn&i._10pct %end;  ; quit; run;
	*Create a name variable for each table (should not have to do this for the final implementation);
    %do m = 1 %to &ndsn.; 
	    data dsn&m._01pct_stats;
		    format id $30.;
		    *length id $ 30;
            set dsn&m._01pct_stats;
			id = "dsn&m._01pct_stats";
        run;
        data dsn&m._05pct_stats;
		    format id $30.;
		    *length id $ 30;
            set dsn&m._05pct_stats;
			id = "dsn&m._05pct_stats";
        run;
        data dsn&m._10pct_stats;
		    format id $30.;
		    *length id $ 30;
            set dsn&m._10pct_stats;
			id = "dsn&m._10pct_stats";
        run;
    %end;
    *Get the grand totals for each individual dataset;
    %do m = 1 %to &ndsn.; 
        proc sql noprint;
            create table 		dsn&m._01pct_stats_0 as
            select  			unique a.id, a.total
            from 				dsn&m._01pct_stats a
            order by            a.id;
        quit;
		data dsn&m._01pct_stats_0(rename=(total=_FREQ_));
		    set dsn&m._01pct_stats_0;
        run; 
	    proc sql noprint;
            create table 		dsn&m._05pct_stats_0 as
            select  			unique a.id, a.total
            from 				dsn&m._05pct_stats a
            order by            a.id;
        quit;
		data dsn&m._05pct_stats_0(rename=(total=_FREQ_));
		    set dsn&m._05pct_stats_0;
        run; 
        proc sql noprint;
            create table 		dsn&m._10pct_stats_0 as
            select  			unique a.id, a.total
            from 				dsn&m._10pct_stats a
            order by            a.id;
        quit;
		data dsn&m._10pct_stats_0(rename=(total=_FREQ_));
		    set dsn&m._10pct_stats_0;
        run; 
    %end;
    *Get the unique grand totals for each individual dataset;
    %do m = 1 %to &ndsn.; 
	    data dsn&m._01pct_stats_1;
            set dsn&m._01pct_stats;
			if &col.="" then delete;
        run;
        proc sql noprint;
            create table 		dsn&m._01pct_stats_1_u as
            select  			unique a.id, a.&col., count(a.&col.) as counts
            from 				dsn&m._01pct_stats_1 a;
        quit;
		proc sql noprint;
            create table 		dsn&m._01pct_stats_1_u2 as
            select  			unique a.id, a.counts
            from 				dsn&m._01pct_stats_1_u a;
        quit;
	    data dsn&m._05pct_stats_1;
            set dsn&m._05pct_stats;
			if &col.="" then delete;
        run;
        proc sql noprint;
            create table 		dsn&m._05pct_stats_1_u as
            select  			unique a.id, a.&col., count(a.&col.) as counts
            from 				dsn&m._05pct_stats_1 a;
        quit;
		proc sql noprint;
            create table 		dsn&m._05pct_stats_1_u2 as
            select  			unique a.id, a.counts
            from 				dsn&m._05pct_stats_1_u a;
        quit;
	    data dsn&m._10pct_stats_1;
            set dsn&m._10pct_stats;
			if &col.="" then delete;
        run;
        proc sql noprint;
            create table 		dsn&m._10pct_stats_1_u as
            select  			unique a.id, a.&col., count(a.&col.) as counts
            from 				dsn&m._10pct_stats_1 a;
        quit;
		proc sql noprint;
            create table 		dsn&m._10pct_stats_1_u2 as
            select  			unique a.id, a.counts
            from 				dsn&m._10pct_stats_1_u a;
        quit;
    %end;
	proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._01pct_stats_1 dsn&i._05pct_stats_1 dsn&i._10pct_stats_1 %end;  ; quit; run;
	proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._01pct_stats_1_u dsn&i._05pct_stats_1_u dsn&i._10pct_stats_1_u %end;  ; quit; run;
	*Combine table *_stats_0 and *_stats_1_u2;
    %do m = 1 %to &ndsn.; 
        proc sql noprint;
            create table 		dsn&m._01pct_stats_2 as
            select  			a.id, a._FREQ_, b.counts
            from 				dsn&m._01pct_stats_0 a, dsn&m._01pct_stats_1_u2 b
            where               a.id=b.id;
        quit;
	    proc sql noprint;
            create table 		dsn&m._05pct_stats_2 as
            select  			a.id, a._FREQ_, b.counts
            from 				dsn&m._05pct_stats_0 a, dsn&m._05pct_stats_1_u2 b
            where               a.id=b.id;
        quit;
        proc sql noprint;
            create table 		dsn&m._10pct_stats_2 as
            select  			a.id, a._FREQ_, b.counts
            from 				dsn&m._10pct_stats_0 a, dsn&m._10pct_stats_1_u2 b
            where               a.id=b.id;
        quit;
    %end;
    proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._01pct_stats_0 dsn&i._05pct_stats_0 dsn&i._10pct_stats_0 %end;  ; quit; run;
	proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._01pct_stats_1_u2 dsn&i._05pct_stats_1_u2 dsn&i._10pct_stats_1_u2 %end;  ; quit; run;
	*merge the percentile totals;
    data dsn_global_01pct_totals0(rename=(_FREQ_=grand_totals_01 counts=distinct_totals_01));
        set %do m = 1 %to &ndsn.; dsn&m._01pct_stats_2 %end; ;  
    run;
	data dsn_global_05pct_totals0(rename=(_FREQ_=grand_totals_05 counts=distinct_totals_05));
        set %do m = 1 %to &ndsn.; dsn&m._05pct_stats_2 %end; ;  
    run;
	data dsn_global_10pct_totals0(rename=(_FREQ_=grand_totals_10 counts=distinct_totals_10));
        set %do m = 1 %to &ndsn.; dsn&m._10pct_stats_2 %end; ;  
    run;
	proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._01pct_stats_2 dsn&i._05pct_stats_2 dsn&i._10pct_stats_2 %end;  ; quit; run;
    *Add the global counts so that the score can be created;
	proc sql noprint;
        select   global_grand_totals_01, global_distinct_totals_01  
        into     :global_grand_totals_01, :global_distinct_totals_01
        from     Dsn_global_01pct_stats_2
    quit;
    data dsn_global_01pct_totals0;
	    set dsn_global_01pct_totals0;
		global_grand_totals_01 = &global_grand_totals_01.;
        global_distinct_totals_01 = &global_distinct_totals_01.;
	run;
    proc sql noprint;
        select   global_grand_totals_05, global_distinct_totals_05 
        into     :global_grand_totals_05, :global_distinct_totals_05
        from     Dsn_global_05pct_stats_2
    quit;
    data dsn_global_05pct_totals0;
	    set dsn_global_05pct_totals0;
		global_grand_totals_05 = &global_grand_totals_05.;
        global_distinct_totals_05 = &global_distinct_totals_05.;
	run;
    proc sql noprint;
        select   global_grand_totals_10, global_distinct_totals_10
        into     :global_grand_totals_10, :global_distinct_totals_10
        from     Dsn_global_10pct_stats_2
    quit;
    data dsn_global_10pct_totals0;
	    set dsn_global_10pct_totals0;
		global_grand_totals_10 = &global_grand_totals_10.;
        global_distinct_totals_10 = &global_distinct_totals_10.;
	run;
	/*proc datasets lib=work nolist; delete dsn_global_01pct_stats_2 dsn_global_05pct_stats_2 dsn_global_10pct_stats_2 ; quit; run;*/
	*Create the scores;
    data dsn_global_01pct_totals0;
	    format grand_total_score_01 10.8 distinct_total_score_01 10.8;
	    set dsn_global_01pct_totals0;
		grand_total_score_01 = grand_totals_01/global_grand_totals_01;
        distinct_total_score_01 = distinct_totals_01/global_distinct_totals_01;
	run;
    data dsn_global_05pct_totals0;
		format grand_total_score_05 10.8 distinct_total_score_05 10.8;
	    set dsn_global_05pct_totals0;
		grand_total_score_05 = grand_totals_05/global_grand_totals_05;
        distinct_total_score_05 = distinct_totals_05/global_distinct_totals_05;
	run;
	data dsn_global_10pct_totals0;
		format grand_total_score_10 10.8 distinct_total_score_10 10.8;
	    set dsn_global_10pct_totals0;
		grand_total_score_10 = grand_totals_10/global_grand_totals_10;
        distinct_total_score_10 = distinct_totals_10/global_distinct_totals_10;
	run;
	*Reorder the columns;
    proc sql noprint;
        create table 		dsn_global_01pct_totals as
        select  			a.id, a.grand_totals_01, a.global_grand_totals_01, a.grand_total_score_01, a.distinct_totals_01, a.global_distinct_totals_01, a.distinct_total_score_01
        from 				dsn_global_01pct_totals0 a;
    quit;
    proc sql noprint;
        create table 		dsn_global_05pct_totals as
        select  			a.id, a.grand_totals_05, a.global_grand_totals_05, a.grand_total_score_05, a.distinct_totals_05, a.global_distinct_totals_05, a.distinct_total_score_05
        from 				dsn_global_05pct_totals0 a;
    quit;
    proc sql noprint;
        create table 		dsn_global_10pct_totals as
        select  			a.id, a.grand_totals_10, a.global_grand_totals_10, a.grand_total_score_10, a.distinct_totals_10, a.global_distinct_totals_10, a.distinct_total_score_10
        from 				dsn_global_10pct_totals0 a;
    quit;
	proc datasets lib=work nolist; delete dsn_global_01pct_totals0 dsn_global_05pct_totals0 dsn_global_10pct_totals0 ; quit; run;
	*Create summary statistics;
    proc means data=dsn_global_01pct_totals noprint;
	    var grand_totals_01 distinct_totals_01 grand_total_score_01 distinct_total_score_01;
        output out=dsn_global_01pct_sumstats;
    run;
	proc means data=dsn_global_05pct_totals noprint;
	    var grand_totals_05 distinct_totals_05 grand_total_score_05 distinct_total_score_05;
        output out=dsn_global_05pct_sumstats;
    run;
	proc means data=dsn_global_10pct_totals noprint;
	    var grand_totals_10 distinct_totals_10 grand_total_score_10 distinct_total_score_10;
        output out=dsn_global_10pct_sumstats;
    run;
	*Create a temp id variable so the tables can be joined;
    data dsn_global_01pct_totals1(drop=id);
	    format id1 $30.;
	    set dsn_global_01pct_totals;
		id1=substr(id,1,find(id,"_",1)-1);
	run;
	data dsn_global_05pct_totals1(drop=id);
	    format id1 $30.;
	    set dsn_global_05pct_totals;
		id1=substr(id,1,find(id,"_",1)-1);
	run;
	data dsn_global_10pct_totals1(drop=id);
	    format id1 $30.;
	    set dsn_global_10pct_totals;
		id1=substr(id,1,find(id,"_",1)-1);
	run;
	/* proc datasets lib=work nolist; delete dsn_global_01pct_totals dsn_global_05pct_totals dsn_global_10pct_totals ; quit; run;*/
    *Merge the tables with the scores;
    proc sql noprint;
        create table 		dsn_global_totals as
        select  			a.id1, 
                            a.grand_totals_01, a.global_grand_totals_01, a.grand_total_score_01, a.distinct_totals_01, a.global_distinct_totals_01, a.distinct_total_score_01,
                            b.grand_totals_05, b.global_grand_totals_05, b.grand_total_score_05, b.distinct_totals_05, b.global_distinct_totals_05, b.distinct_total_score_05,
							c.grand_totals_10, c.global_grand_totals_10, c.grand_total_score_10, c.distinct_totals_10, c.global_distinct_totals_10, c.distinct_total_score_10
        from 				dsn_global_01pct_totals1 a, dsn_global_05pct_totals1 b, dsn_global_10pct_totals1 c
		where               a.id1=b.id1
		and                 b.id1=c.id1
        and                 a.id1=c.id1;
    quit;
	data dsn_global_totals(rename=(id1=id));
	    set dsn_global_totals;
	run;
    proc datasets lib=work nolist; delete dsn_global_01pct_totals1 dsn_global_05pct_totals1 dsn_global_10pct_totals1 ; quit; run;

%mend split;

/*
%macro split;
%mend split;
*/


*Call the macro Split that splits the descriptions into single datasets;
%split(ndsn=&nobsid.,ds=textparse_match_trim,col=Match_Text);

*Merge the output from the macro with the dataset;
proc sql noprint;
    create table 		Final_Stats as
    select  			a.*,b.* 
    from 				textparse_match_final a, dsn_global_totals b
    where               a.id=b.id;
quit;
/*
data Final_Stats(drop=id);
    set Final_Stats;
run;
*/
*********************************************************************************
Sign off if using SAS/Connect to WRDS
*********************************************************************************;
*signoff;




   *TODO;
	*Work on the output that is shown -- SQL no print, etc.
	*Fix paraparse and update column so that algorithm will work.
	*Find out why output is only 62 columns;

