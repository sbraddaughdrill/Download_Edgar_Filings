*=====================================================================;
*PROGRAM DETAILS;
*=====================================================================;
*Program: 	Import_TR_MF_Holdings.sas;
*Version: 	1.0;
*Author:    S. Brad Daughdrill;
*Date:		03.19.2012;
*Purpose:	Import data from WRDS Thomson-Reuters Mutual Fund Holdings database;
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
*Assign libnames
*=====================================================================;
*Assign local libnames;
libname myhome remote  '.' server=WRDS;
libname mycrsp remote  '/wrds/crsp/sasdata/q_mutualfunds' server=WRDS;
libname mymfl remote  '/wrds/mfl/sasdata' server=WRDS;
libname mytfn remote  '/wrds/tfn/sasdata/s12' server=WRDS;
*Assign libnames on WRDS server;
*(Note: libname CRSP is automatically created);
rsubmit;
libname wrdshome '.'; 
libname wrdscrsp '/wrds/crsp/sasdata/q_mutualfunds';
libname wrdsmfl '/wrds/mfl/sasdata';
libname wrdstfn '/wrds/tfn/sasdata/s12';
endrsubmit;
*********************************************************************************;
*STEP ONE: CRSP data;
*********************************************************************************;
*Table Holdings - Portfolio holding information;
rsubmit;
%let my_holdings_yrstrt = 2007;			
%let my_holdings_yrend = 2008;
%let my_holdings_vars = crsp_portno report_dt security_rank eff_dt percent_tna nbr_shares market_val crsp_company_key security_name cusip permno permco ticker coupon maturity_dt;
data my_holdings(keep = &my_holdings_vars.);	
    set crsp.holdings;
    *where year(report_dt) between (&my_holdings_yrstrt.-1) and (&my_holdings_yrend.+1); 
    where year(report_dt) between (&my_holdings_yrstrt.) and (&my_holdings_yrend.); 
run;
proc download data=my_holdings out=my_holdings; run;
endrsubmit;

******************************************************;
proc sort data=my_holdings;
by report_dt;
run;

******************************************************;
rsubmit;
proc sql;
    create table temp1 as
    select    b.crsp_fundno, a.crsp_portno, a.report_dt, a.security_rank, a.eff_dt, a.percent_tna, a.nbr_shares, a.market_val, a.crsp_company_key, a.security_name
    from      crsp.holdings as a, crsp.portnomap as b
    where     a.crsp_portno=b.crsp_portno
    and       b.crsp_fundno=002761
    group by  a.crsp_portno
    having    report_dt eq max(report_dt);
quit;
/* Retrieve the holdings company information from Holdings_co_info dataset. */
proc sort data=temp1 out=temp1_order; by crsp_company_key; run;
proc download data=temp1_order out=temp1_order; run;
data temp2;
    merge temp1_order(in=in1) crsp.holdings_co_info(in=in2);
    by crsp_company_key;
    if in1 and in2;
run;
proc sort data=temp2 out=portfolio; by security_rank; run;
proc download data=temp2 out=temp2; run;
/*Delete all temporary datasets.*/
proc datasets; delete temp1 temp1_order temp2;quit; run;
endrsubmit;





rsubmit;
proc sql;
    create table temp3 as
    select    b.crsp_fundno, a.crsp_portno, a.report_dt, a.security_rank, a.eff_dt, a.percent_tna, a.nbr_shares, a.market_val, a.crsp_company_key, a.security_name
    from      crsp.holdings as a, crsp.portnomap as b
    where     a.crsp_portno=b.crsp_portno
    group by  a.crsp_portno
    having    report_dt eq max(report_dt);
quit;
proc sort data=temp3 out=temp3_order; by crsp_portno report_dt security_rank; run;
proc download data=temp3_order out=temp3_order; run;
%let my_portfolio_yrstrt = 2007;			
%let my_portfolio_yrend = 2008;
data temp3_t;	
    set temp3;
    *where year(report_dt) between (&my_portfolio_yrstrt.-1) and (&my_portfolio_yrend.+1); 
    where year(report_dt) between (&my_portfolio_yrstrt.) and (&my_portfolio_yrend.); 
run;
/* Retrieve the holdings company information from Holdings_co_info dataset. */
proc sort data=temp3_t out=temp3_t_order; by crsp_portno report_dt security_rank; run;
proc download data=temp3_t_order out=temp3_t_order; run;
endrsubmit;

data temp3_t_order_test;
    set temp3_t_order;
    where crsp_fundno=002761;
run;

rsubmit;
%let my_portfolio_yrstrt = 2007;			
%let my_portfolio_yrend = 2008;
proc sql;
    create table temp5 as
    select    b.crsp_fundno, a.crsp_portno, a.report_dt, a.security_rank, a.eff_dt, a.percent_tna, a.nbr_shares, a.market_val, a.crsp_company_key, a.security_name
    from      crsp.holdings as a, crsp.portnomap as b
    where     year(a.report_dt) between (&my_portfolio_yrstrt.) and (&my_portfolio_yrend.)
	and       a.crsp_portno=b.crsp_portno
    group by  a.crsp_portno
    having    report_dt eq max(report_dt)
    order by  crsp_portno, report_dt, security_rank;
quit;
/*proc sort data=temp5 out=temp5_order; by crsp_portno report_dt security_rank; run;
proc download data=temp5_order out=temp5_order; run;*/
proc download data=temp5 out=temp5; run;
endrsubmit;

rsubmit;
proc download data=temp5 out=temp5; run;
endrsubmit;

data temp5_test;
    set temp5;
    where crsp_fundno=002761;
run;

rsubmit;
proc sql;
    create table temp4 as
    select    b.crsp_fundno, a.crsp_portno, a.report_dt, a.security_rank, a.eff_dt, a.percent_tna, a.nbr_shares, a.market_val, a.crsp_company_key, a.security_name
    from      crsp.holdings as a, crsp.portnomap as b
    where     a.crsp_portno=b.crsp_portno
    and       b.crsp_fundno=002761
    group by  a.crsp_portno
    having    report_dt eq max(report_dt);
quit;
proc sort data=temp4 out=temp4_order; by crsp_portno report_dt security_rank; run;
proc download data=temp4_order out=temp4_order; run;
endrsubmit;

rsubmit;
%let my_portfolio_yrstrt = 2007;			
%let my_portfolio_yrend = 2008;
proc sql;
    create table temp6 as
    select    b.crsp_fundno, a.crsp_portno, a.report_dt, a.security_rank, a.eff_dt, a.percent_tna, a.nbr_shares, a.market_val, a.crsp_company_key, a.security_name
    from      crsp.holdings as a, crsp.portnomap as b
    where     year(a.report_dt) between (&my_portfolio_yrstrt.) and (&my_portfolio_yrend.)
	and       a.crsp_portno=b.crsp_portno
    group by  b.crsp_fundno, a.crsp_portno
    having    report_dt eq max(report_dt)
    order by  crsp_fundno, crsp_portno, report_dt, security_rank;
quit;
/*proc sort data=temp5 out=temp5_order; by crsp_portno report_dt security_rank; run;
proc download data=temp5_order out=temp5_order; run;*/
proc download data=temp6 out=temp6; run;
endrsubmit;

*********************************************************************************;
*STEP TWO: MFLinks data;
*********************************************************************************;
data mflink1;	
    set mymfl.mflink1;
run;



*********************************************************************************;
*STEP THREE: Thomson-Reuters Mutual Fund data;
*********************************************************************************;
*Table S12 - Thomson-Reuters Mutual Fund Holdings;
rsubmit;
%let my_s12_yrstrt = 2007;			
%let my_s12_yrend = 2008;
%let my_s12_vars = fdate fundno fundname mgrcoab rdate assets ioc prdate country cusip shares change stkname ticker exchcd stkcd indcode stkcdesc prc shrout1 shrout2;
data my_s12(keep = &my_s12_vars.);	
    set tfn.s12;
    *where year(fdate) between (&my_s12_yrstrt.-1) and (&my_s12_yrend.+1); 
    where year(fdate) between (&my_s12_yrstrt.) and (&my_s12_yrend.); 
run;
proc download data=my_s12 out=my_s12; run;
endrsubmit;

*Table S12names - TFN Mutual Fund Basic Information;
rsubmit;
%let my_S12names_vars = fundno fundname mgrcoab ioc country rdate1 rdate2;
data my_S12names(keep = &my_S12names_vars.);	
    set tfn.S12names; 
run;
proc download data=my_S12names out=my_S12names; run;
endrsubmit;

*Table S12type1 - TFN Mutual Funds Managers (CDA/Spectrum s12 type 1 table);
rsubmit;
%let my_S12type1_yrstrt = 2008;			
%let my_S12type1_yrend = 2008;
%let my_S12type1_vars = fdate fundno fundname mgrcoab rdate assets ioc prdate country ;
data my_S12type1(keep = &my_S12type1_vars.);	
    set tfn.S12type1;
    where year(fdate) between (&my_S12type1_yrstrt.-1) and (&my_S12type1_yrend.+1); 
run;
proc download data=my_S12type1 out=my_S12type1; run;
endrsubmit;

*Table S12type2 - TFN Mutual Funds Securities Information (CDA/Spectrum s12 type 2 table);
rsubmit;
%let my_S12type2_yrstrt = 2008;			
%let my_S12type2_yrend = 2008;
%let my_S12type2_vars = fdate cusip stkname ticker ticker2 exchcd stkcd stkcdesc shrout1 prc shrout2 indcode;
data my_S12type2(keep = &my_S12type2_vars.);	
    set tfn.S12type2;
    where year(fdate) between (&my_S12type2_yrstrt.-1) and (&my_S12type2_yrend.+1); 
run;
proc download data=my_S12type2 out=my_S12type2; run;
endrsubmit;

*Table S12type3 - TFN Mutual Funds Shares Held (CDA/Spectrum s12 type 3 table);
rsubmit;
%let my_S12type3_yrstrt = 2008;			
%let my_S12type3_yrend = 2008;
%let my_S12type3_vars = fdate cusip fundno shares;
data my_S12type3(keep = &my_S12type3_vars.);	
    set tfn.S12type3;
    where year(fdate) between (&my_S12type3_yrstrt.-1) and (&my_S12type3_yrend.+1); 
run;
proc download data=my_S12type3 out=my_S12type3; run;
endrsubmit;

*Table S12type4 - TFN Mutual Funds Changes in Shares Held (CDA/Spectrum s12 type 4 table);
rsubmit;
%let my_S12type4_yrstrt = 2008;			
%let my_S12type4_yrend = 2008;
%let my_S12type4_vars = fdate cusip fundno change;
data my_S12type4(keep = &my_S12type4_vars.);	
    set tfn.S12type4;
    where year(fdate) between (&my_S12type4_yrstrt.-1) and (&my_S12type4_yrend.+1); 
run;
proc download data=my_S12type4 out=my_S12type4; run;
endrsubmit;

*Table S12type5 - TFN Mutual Funds (CDA/Spectrum) S12 type 5 table;
rsubmit;
%let my_S12type5_yrstrt = 2008;			
%let my_S12type5_yrend = 2008;
%let my_S12type5_vars = fdate fundname mgrco fundno mgrcocd;
data my_S12type5(keep = &my_S12type5_vars.);	
    set tfn.S12type5;
    where year(fdate) between (&my_S12type5_yrstrt.-1) and (&my_S12type5_yrend.+1); 
run;
proc download data=my_S12type5 out=my_S12type5; run;
endrsubmit;

*Table S12type6 - TFN Mutual Funds (CDA/Spectrum) S12 type 6 table;
rsubmit;
%let my_S12type6_yrstrt = 2008;			
%let my_S12type6_yrend = 2008;
%let my_S12type6_vars = fdate fundno permkey;
data my_S12type6(keep = &my_S12type6_vars.);	
    set tfn.S12type6;
    where year(fdate) between (&my_S12type6_yrstrt.-1) and (&my_S12type6_yrend.+1); 
run;
proc download data=my_S12type6 out=my_S12type6; run;
endrsubmit;

*Table S12type7 - TFN Mutual Funds (CDA/Spectrum) S12 type 7 table;
rsubmit;
%let my_S12type7_yrstrt = 2008;			
%let my_S12type7_yrend = 2008;
%let my_S12type7_vars = fdate mgrcoab mgrco;
data my_S12type7(keep = &my_S12type7_vars.);	
    set tfn.S12type7;
    where year(fdate) between (&my_S12type7_yrstrt.-1) and (&my_S12type7_yrend.+1); 
run;
proc download data=my_S12type7 out=my_S12type7; run;
endrsubmit;

*Table S12type8 - TFN Mutual Funds (CDA/Spectrum) S12 type 8 table;
rsubmit;
%let my_S12type8_yrstrt = 2008;			
%let my_S12type8_yrend = 2008;
%let my_S12type8_vars = fdate fticker fundno tfsdid;
data my_S12type8(keep = &my_S12type8_vars.);	
    set tfn.S12type8;
    where year(fdate) between (&my_S12type8_yrstrt.-1) and (&my_S12type8_yrend.+1); 
run;
proc download data=my_S12type8 out=my_S12type8; run;
endrsubmit;

******************************************************;
proc sort data=my_s12;
by fundno;
run;

*********************************************************************************
Sign off if using SAS/Connect to WRDS
*********************************************************************************;
*signoff;
