*=====================================================================;
*PROGRAM DETAILS;
*=====================================================================;
*Program: 	Web_Crawler_Test.sas;
*Version: 	1.0;
*Author:    S. Brad Daughdrill;
*Date:		03.03.2012;
*Purpose:	Test webcrawler script;
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
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
%DeleteMacros;
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
*%IncludeMacros (projfolder=&projectrootdirectory.,researchfolder=&fullmacrodirectory.);
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
*Create test databases;
*=====================================================================;
data work.test;
    infile cards;
    length in $ 100;
    input in &;
    cards;
Hello world
This is a longer sentence
   
;
run;

filename rc_test "&projectrootdirectory.\Data\Test\test_wc_input.txt" lrecl=32767;
proc import datafile=rc_test out=work.test2 dbms=DLM replace;
    delimiter='20'x;
    getnames=no;
    datarow=1;
	guessingrows=32767;
run;
data work.test2(drop=var2-var5);
	set work.test2(rename=(var1=description_temp));
run;
data work.test2(drop=description_temp);
	length description $32767;
	set work.test2;
	description=description_temp;
run;
data &testdatalibrary..test2;
    set test2;
run;
data &emdatalibrary..test2;
    set test2;
run;
*=====================================================================;
*Cleanup descriptions;
*=====================================================================;
data work.test2_trim(drop=description description_compress1-description_compress3 description_compbl description_trim);
    set work.test2;
    description_compress1=compress(description,,"p");  *Compressing punctuation characters;
    description_compress2=compress(description_compress1,"+-","d");  *Compressing digits and plus/minus signs characters;
    description_compress3=compress(description_compress2,,"c");  *Compressing control characters;
    description_compbl=compbl(description_compress3);
    description_trim=trim(description_compbl);
    description_upcase = upcase(description_trim);
run;
data work.test2_trim(rename=(description_upcase=description));
    set work.test2_trim;
    if description_upcase="" then delete;
run;
*Determine number of observations;
data _null_;
	set work.test2_trim end=last;
	*call symputx("descriptionid"||left(put(_n_,4.)), trim(left(description)),L);
	call symput ("nobsid", _n_); * keep overwriting value until end = total obs.;
run;
*Save datasets;
data &testdatalibrary..test2_trim;
    set test2_trim;
run;
data &emdatalibrary..test2_trim;
    set test2_trim;
run;

*=====================================================================;
*Split Macros;
*=====================================================================;

*options mprint symbolgen mlogic spool;
options nomprint nosymbolgen nomlogic;

*define the macro Explode;
%macro explode(text=,dataset=,delim=,arrayref=);
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
    %end;
%mend explode;

*define the macro Split;
%macro split(ndsn=,ds=); 
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
        %explode(text=description, dataset=dsn&l., delim=%str( ), arrayRef=y&l.);
    %end;
    proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i. %end;  ; quit; run;
    *transpose descriptions and delete temporary datasets;
    %do m = 1 %to &ndsn.; 
        proc transpose data=dsn&m._out out=dsn&m._out_t;
            var _ALL_;
        run;
        data dsn&m._out_t(drop=_Name_);
            set dsn&m._out_t(rename=(COL1=dictionary));
	        if _N_=1 then delete;
        run;
    %end;
    proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._out %end;  ; quit; run;
    *sort the datasets for merging and create summary statistics;
    %do m = 1 %to &ndsn.; 
	    proc sort data=dsn&m._out_t;
	        by dictionary;
        run;
	    proc means data=dsn&m._out_t noprint;
	        class dictionary;
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
            by descending _FREQ_ dictionary;
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
		class dictionary;
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
	    by descending _FREQ_ dictionary;
    run;
	proc datasets lib=work nolist; delete dsn_global ; quit; run;
    *find the top x% entries;
    proc sql noprint;
        select   count(dictionary) into: global_distinct_words
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
        by descending word_01pct_dv descending word_05pct_dv descending word_10pct_dv descending _FREQ_ dictionary;
    run;
	*Create individual dicitonary for 1% most commonly used words;
    proc sql;
        create table 		dsn_global_01pct_list as
        select  			a.dictionary
        from 				dsn_global_stats a
        where               word_01pct_dv=1
        order by            a.dictionary;
    quit;
    data _null_;
	     set dsn_global_01pct_list end=last;
	     call symputx("descrip_01pct"||left(put(_n_,4.)), trim(left(dictionary)),L);
	     call symput ("nobsid_01pct", _n_); * keep overwriting value until end = total obs.;
    run;
	*Create individual dicitonary for 5% most commonly used words;
	proc sql;
        create table 		dsn_global_05pct_list as
        select  			a.dictionary
        from 				dsn_global_stats a
        where               word_05pct_dv=1
        order by            a.dictionary;
    quit;
	data _null_;
	     set dsn_global_05pct_list end=last;
	     call symputx("descrip_05pct"||left(put(_n_,4.)), trim(left(dictionary)),L);
	     call symput ("nobsid_05pct", _n_); * keep overwriting value until end = total obs.;
    run;
	*Create individual dicitonary for 10% most commonly used words;
	proc sql;
        create table 		dsn_global_10pct_list as
        select  			a.dictionary
        from 				dsn_global_stats a
        where               word_10pct_dv=1
        order by            a.dictionary;
    quit;
	*Determine 10% most commonly used words;
	data _null_;
	     set dsn_global_10pct_list end=last;
	     call symputx("descrip_10pct"||left(put(_n_,4.)), trim(left(dictionary)),L);
	     call symput ("nobsid_10pct", _n_); * keep overwriting value until end = total obs.;
    run;
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
			    if dictionary in ( %do i = 1 %to &nobsid_01pct.; "&&descrip_01pct&i"    %end;  ) then do;
                    word_01pct_dv=1;
                end;
			    else do;
                    word_01pct_dv=0;
                end;
			    if dictionary in ( %do i = 1 %to &nobsid_05pct.; "&&descrip_05pct&i"    %end;  ) then do;
                    word_05pct_dv=1;
                end;
			    else do;
                    word_05pct_dv=0;
                end;
			    if dictionary in ( %do i = 1 %to &nobsid_10pct.; "&&descrip_10pct&i"    %end;  ) then do;
                    word_10pct_dv=1;
                end;
			    else do;
                    word_10pct_dv=0;
                end;
            end;
        run;
        proc sort data=dsn&m._all_stats;
            by descending word_01pct_dv descending word_05pct_dv descending word_10pct_dv descending _FREQ_ dictionary;
        run;
	%end;
	/*proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._out_t_stats %end;  ; quit; run;*/
    *Create tables based on the percentiles;
    %do m = 1 %to &ndsn.; 
	    proc sql;
            create table 		dsn&m._01pct as
            select  			a.dictionary
            from 				dsn&m._all_stats a
            where               word_01pct_dv=0
            order by            a.dictionary;
        quit;
	    proc sql;
            create table 		dsn&m._05pct as
            select  			a.dictionary
            from 				dsn&m._all_stats a
            where               word_05pct_dv=0
            order by            a.dictionary;
        quit;
	    proc sql;
            create table 		dsn&m._10pct as
            select  			a.dictionary
            from 				dsn&m._all_stats a
            where               word_10pct_dv=0
            order by            a.dictionary;
        quit;
    %end;
	
	*sort the datasets for merging and create summary statistics for the trimmed 1 percentile;
    %do m = 1 %to &ndsn.; 
	    proc sort data=dsn&m._01pct;
	        by dictionary;
        run;
	    proc means data=dsn&m._01pct noprint;
	        class dictionary;
            output out=dsn&m._01pct_stats;
        run;
		proc sql noprint;
            select   _FREQ_ into: total_words_01pct_&m.
            from     dsn&m._01pct_stats
			where    _TYPE_=0;
        quit;
	    data dsn&m._01pct_stats;
            set dsn&m._01pct_stats;
			total_percentage=_FREQ_ / &&total_words_01pct_&m.;
        run;
        proc sort data=dsn&m._01pct_stats;
            by descending _TYPE_ dictionary;
        run;
    %end;	
	*sort the datasets for merging and create summary statistics for the trimmed 5 percentile;
    %do m = 1 %to &ndsn.; 
	    proc sort data=dsn&m._05pct;
	        by dictionary;
        run;
	    proc means data=dsn&m._05pct noprint;
	        class dictionary;
            output out=dsn&m._05pct_stats;
        run;
		proc sql noprint;
            select   _FREQ_ into: total_words_05pct_&m.
            from     dsn&m._05pct_stats
			where    _TYPE_=0;
        quit;
	    data dsn&m._05pct_stats;
            set dsn&m._05pct_stats;
			total_percentage=_FREQ_ / &&total_words_05pct_&m.;
        run;
        proc sort data=dsn&m._05pct_stats;
            by descending _TYPE_ dictionary;
        run;
    %end;
    *sort the datasets for merging and create summary statistics for the trimmed 10 percentile;
    %do m = 1 %to &ndsn.; 
	    proc sort data=dsn&m._10pct;
	        by dictionary;
        run;
	    proc means data=dsn&m._10pct noprint;
	        class dictionary;
            output out=dsn&m._10pct_stats;
        run;
		proc sql noprint;
            select   _FREQ_ into: total_words_10pct_&m.
            from     dsn&m._10pct_stats
			where    _TYPE_=0;
        quit;
	    data dsn&m._10pct_stats;
            set dsn&m._10pct_stats;
			total_percentage=_FREQ_ / &&total_words_10pct_&m.;
        run;
        proc sort data=dsn&m._10pct_stats;
            by descending _TYPE_ dictionary;
        run;
    %end;
	
	proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._01pct dsn&i._05pct dsn&i._10pct %end;  ; quit; run;
	*Create a name variable for each table (should not have to do this for the final implementation);
    %do m = 1 %to &ndsn.; 
	    data dsn&m._01pct_stats;
            set dsn&m._01pct_stats;
			id = "dsn&m._01pct_stats";
        run;
        data dsn&m._05pct_stats;
            set dsn&m._05pct_stats;
			id = "dsn&m._05pct_stats";
        run;
        data dsn&m._10pct_stats;
            set dsn&m._10pct_stats;
			id = "dsn&m._10pct_stats";
        run;
    %end;
    *sort the datasets for merging and create summary statistics;
    %do m = 1 %to &ndsn.; 
        proc sql;
            create table 		dsn&m._01pct_stats_0 as
            select  			a.id, a._FREQ_
            from 				dsn&m._01pct_stats a
            where               _TYPE_=0
            order by            a.id;
        quit;
		proc sql;
            create table 		dsn&m._05pct_stats_0 as
            select  			a.id, a._FREQ_
            from 				dsn&m._05pct_stats a
            where               _TYPE_=0
            order by            a.id;
        quit;
		proc sql;
            create table 		dsn&m._10pct_stats_0 as
            select  			a.id, a._FREQ_
            from 				dsn&m._10pct_stats a
            where               _TYPE_=0
            order by            a.id;
        quit;
		proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._01pct dsn&i._05pct dsn&i._10pct %end;  ; quit; run;
    %end;
	*merge the percentile totals;
    data dsn_global_01pct(rename=(_FREQ_=totals));
        set %do m = 1 %to &ndsn.; dsn&m._01pct_stats_0 %end; ;  
    run;
	data dsn_global_05pct(rename=(_FREQ_=totals));
        set %do m = 1 %to &ndsn.; dsn&m._05pct_stats_0 %end; ;  
    run;
	data dsn_global_10pct(rename=(_FREQ_=totals));
        set %do m = 1 %to &ndsn.; dsn&m._10pct_stats_0 %end; ;  
    run;
	proc datasets lib=work nolist; delete %do i = 1 %to &ndsn.; dsn&i._01pct_stats_0 dsn&i._05pct_stats_0 dsn&i._10pct_stats_0 %end;  ; quit; run;
    proc means data=dsn_global_01pct noprint;
	    var totals;
        output out=dsn_global_01pct_stats;
    run;
	proc means data=dsn_global_05pct noprint;
	    var totals;
        output out=dsn_global_05pct_stats;
    run;
	proc means data=dsn_global_10pct noprint;
	    var totals;
        output out=dsn_global_10pct_stats;
    run;
    proc datasets lib=work nolist; delete dsn_global_01pct dsn_global_05pct dsn_global_10pct ; quit; run;
%mend split;
/*
%macro split;
%mend split;
*/

*Call the macro Split that splits the descriptions into single datasets;
%split(ndsn=&nobsid.,ds=work.test2_trim);
