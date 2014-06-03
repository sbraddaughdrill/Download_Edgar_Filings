# TODO: Add comment
# 
# Author:  Brad
# File:    Download_All.R
# Version: 1.0
# Date:    02.5.2014
# Purpose: This program reads the company.idx files and then files are 
#          downloaded to separate year directories
###############################################################################

###############################################################################
# INITIAL SETUP;
cat("SECTION: INITIAL SETUP", "\n")
###############################################################################

# Clear workspace
rm(list = ls(all = TRUE))

# Limit History to not exceed 50 lines
Sys.setenv(R_HISTSIZE = 500)

repo <- c("http://cran.us.r-project.org")
options(repos = structure(repo))
options(install.packages.check.source = FALSE)
# String as factors is False -- used for read.csv
options(StringsAsFactors = FALSE)

# Default maxprint option
options(max.print = 500)
# options(max.print=99999)

# Memory limit
#memory.limit(size = 8183)

# Set location (1=HOME,2=WORK,3=CORALSEA FROM HOME,4=CORALSEA FROM WORK) Location <- 1
Location <- 1

if (Location == 1) {
  #setwd("C:/Research_temp3/")
  input_directory <- normalizePath("C:/Users/S.Brad/Dropbox/Research/Fund_Letters/Data",winslash="\\", mustWork=TRUE)
  output_directory <- normalizePath("F:/Research_temp3",winslash="\\", mustWork=TRUE)
  function_directory <- normalizePath("C:/Users/S.Brad/Dropbox/Research_Methods/R", winslash = "\\", mustWork = TRUE)
  treetag_directory <- normalizePath("C:/TreeTagger",winslash="\\", mustWork=TRUE)    
  
} else if (Location == 2) {
  #setwd("C:/Research_temp3/")
  input_directory <- normalizePath("C:/Users/bdaughdr/Dropbox/Research/Fund_Letters/Data",winslash="\\", mustWork=TRUE)
  output_directory <- normalizePath("C:/Research_temp3",winslash="\\", mustWork=TRUE)
  function_directory <- normalizePath("C:/Users/bdaughdr/Dropbox/Research_Methods/R",winslash="\\", mustWork=TRUE) 
  treetag_directory <- normalizePath("C:/TreeTagger",winslash="\\", mustWork=TRUE)    
  
} else if (Location == 3) {
  #setwd("//tsclient/C/Research_temp3/")
  input_directory <- normalizePath("H:/Research/Mutual_Fund_Letters/Data", winslash = "\\", mustWork = TRUE)
  #output_directory <- normalizePath("//tsclient/C/Research_temp3", winslash = "\\", mustWork = TRUE)
  output_directory <- normalizePath("C:/Users/bdaughdr/Documents/Research_temp3",winslash="\\", mustWork=TRUE)
  function_directory <- normalizePath("//tsclient/C/Users/S.Brad/Dropbox/Research_Methods/R", winslash = "\\", mustWork = TRUE)
  treetag_directory <- normalizePath("//tsclient/C/TreeTagger",winslash="\\", mustWork=TRUE)    
  
} else if (Location == 4) {
  #setwd("//tsclient/C/Research_temp3/")
  input_directory <- normalizePath("H:/Research/Mutual_Fund_Letters/Data", winslash = "\\", mustWork = TRUE)
  #output_directory <- normalizePath("//tsclient/C/Research_temp3", winslash = "\\", mustWork = TRUE)
  output_directory <- normalizePath("C:/Users/bdaughdr/Documents/Research_temp3",winslash="\\", mustWork=TRUE)
  function_directory <- normalizePath("//tsclient/C/Users/bdaughdr/Dropbox/Research_Methods/R", winslash = "\\", mustWork = TRUE)
  treetag_directory <- normalizePath("//tsclient/C/TreeTagger",winslash="\\", mustWork=TRUE)       
  
} else {
  cat("ERROR ASSIGNING DIRECTORIES", "\n")
  
}
rm(Location)


###############################################################################
# FUNCTIONS;
cat("SECTION: FUNCTIONS", "\n")
###############################################################################

source(file=paste(function_directory,"functions_db.R",sep="\\"),echo=FALSE)
#source(file=paste(function_directory,"functions_statistics.R",sep="\\"),echo=FALSE)
#source(file=paste(function_directory,"functions_text_analysis.R",sep="\\"),echo=FALSE)
source(file=paste(function_directory,"functions_utilities.R",sep="\\"),echo=FALSE)

file_check_http <- function(url_dir,filename){
  
  require(gdata)
  require(memoise)
  
  #url_dir <- "http://www.sec.gov/Archives/edgar/data/933996/000113542805000004/"
  #filename <- "0001135428-05-000004.txt"
  
  output_directory1 <- try(readHTMLTable(url_dir), silent=T)
  if (inherits(output_directory1, "try-error")) 
  {
    filenames <- ""
    filenames2 <- as.data.frame(filenames,stringsAsFactors=FALSE)
    colnames(filenames2)[1] <- "file"
    
  } else
  {
    output_directory2 <- do.call(rbind, output_directory1)
    output_directory3 <- data.frame(lapply(output_directory2, as.character), stringsAsFactors=FALSE)
    colnames(output_directory3) <- c("Trash","Name","Last.modified","Size","Description")
    
    directory_df <- output_directory3
    for(i in 1:ncol(directory_df))
    {
      directory_df[,i] <- iconv(directory_df[,i], "latin1", "ASCII", sub="")
    }
    
    for(i in which(sapply(directory_df,class)=="character"))
    {
      directory_df[[i]] = trim(directory_df[[i]])
    }
    for (i in 1:ncol(directory_df))
    {
      directory_df[,i] <- unknownToNA(directory_df[,i], unknown=c("",".","n/a","na","NA",NA,"null","NULL",NULL,"nan","NaN",NaN,
                                                                  NA_integer_,"NA_integer_",NA_complex_,"NA_complex_",
                                                                  NA_character_,"NA_character_",NA_real_,"NA_real_"),force=TRUE)
      directory_df[,i] <- ifelse(is.na(directory_df[,i]),NA, directory_df[,i])
    } 
    
    #Remove all NA cols
    directory_df <- directory_df[,colSums(is.na(directory_df[1:nrow(directory_df),]))<nrow(directory_df)]
    
    #Remove all NA rows
    directory_df <- directory_df[rowSums(is.na(directory_df[,1:ncol(directory_df)]))<ncol(directory_df),]
    
    #Remove parent directory row
    directory_df <- directory_df[!(directory_df[,"Name"]=="Parent Directory"),]
    
    #Remove NA names row
    directory_df <- directory_df[!(is.na(directory_df[,"Name"])),]
    
    #Reorder row numbers
    row.names(directory_df) <- seq(nrow(directory_df))
    
    for(i in which(sapply(directory_df,class)=="character"))
    {
      directory_df[[i]] = trim(directory_df[[i]])
    }
    for (i in 1:ncol(directory_df))
    {
      #i <- 1
      #i <- 2
      directory_df[,i] <- unknownToNA(directory_df[,i], unknown=c("",".","n/a","na","NA",NA,"null","NULL",NULL,"nan","NaN",NaN,
                                                                  NA_integer_,"NA_integer_",NA_complex_,"NA_complex_",
                                                                  NA_character_,"NA_character_",NA_real_,"NA_real_"),force=TRUE)
    } 
    for(i in which(sapply(directory_df,class)=="character"))
    {
      #i <- 1
      directory_df[[i]] <- ifelse(is.na(directory_df[[i]]),NA, directory_df[[i]])
    }
    
    filenames <- directory_df[,"Name"]
    filenames2 <- as.data.frame(filenames,stringsAsFactors=FALSE)
    colnames(filenames2)[1] <- "file"
    
  }
  
  if (filename %in% filenames2[,"file"]) 
  {
    return(TRUE)
    
  } else
  {
    
    return(FALSE)
    
  }
  
}

file_check_ftp <- function(url_dir,filename){
  
  #url_dir <- "ftp://ftp.sec.gov/edgar/data/933996/000113542805000004/"
  #filename <- "0001135428-05-000004.txt"
  
  output_directory1 <- try(getURL(url_dir, ssl.verifypeer = FALSE, ftp.use.epsv = FALSE, dirlistonly = TRUE), silent=T)
  if (inherits(output_directory1, "try-error")) 
  {
    filenames <- ""
    filenames2 <- as.data.frame(filenames,stringsAsFactors=FALSE)
    colnames(filenames2)[1] <- "file"
    
  } else
  {
    filenames <- data.frame(output_directory1,
                            stringsAsFactors=FALSE)
    filenames2 <-  data.frame(strsplit(filenames[,1], "\r*\n")[[1]],
                              stringsAsFactors=FALSE)
    colnames(filenames2)[1] <- "file"
    
  }
  
  if (filename %in% filenames2[,"file"]) 
  {
    return(TRUE)
    
  } else
  {
    
    return(FALSE)
    
  }
  
}


###############################################################################
# LIBRARIES;
cat("SECTION: LIBRARIES", "\n")
###############################################################################

#Load External Packages
external_packages <- c("gdata","ibdreg","plyr","RCurl")
invisible(unlist(sapply(external_packages,load_external_packages, repo_str=repo, simplify=FALSE, USE.NAMES=FALSE)))
installed_packages <- list_installed_packages(external_packages)

###############################################################################
#PARAMETERS;
###############################################################################

#If using windows, set to "\\" - if mac (or unix), set to "/";
slash <- "\\"

#First year you want index files for:

startyear <- 1993
#startyear <- 2006

#Last year you want index files for:
endyear <- 2013
#endyear <- 2012

#First qtr you want index files for (usually 1):
startqtr <- 1

#Last qtr you want index files for (usually 4):
endqtr <- 4

#Output folder:
indexfolder <- "full-index"

downloadfolder <- "MF_N-1A"
#downloadfolder <- "DEF 14A"
#downloadfolder <- "MF_All"

#The sub directory you are going to download filings to
txtfolder <- "txt"
headerfolder <- "header"

#The file that will contain the filings you want to download.
outfile <- "filings.csv"

outfile_comb <- "filings_list_comb.csv"

#Download address
address_ftp <- "ftp://ftp.sec.gov/"
address_http <- "http://www.sec.gov/Archives/"

#Specifiy, in regular expression format, the filing you are looking for.
#Following is the for 10-k.
#In this case, I only want to keep 10-ks.
#I put a ^ at the beginning because I want the form type to start with 10, this gets rid of NT late filings.
#I also want to exclude amended filings so I specify that 10-k should not be followed by / (e.g., 10-K/A).

#formget <- c("N-1","N-1/A","N-1A","N-1A/A","N-1A EL","N-1A EL/A","497","497J","497K","497K1","497K2","497K3A","497K3B",
#             "N-CSR","N-CSR/A","N-CSRS","N-CSRS/A","N-MFP","N-Q","N-SAR","NSAR-A","NSAR-B","NSAR-B/A","N-PX","485APOS","485BPOS","N-30B-2",
#             "N-14","N-14/A")
#formget <- c("N-1","N-1/A","N-1A","N-1A/A","N-1A EL","N-1A EL/A","497","497J","497K","497K1","497K2","497K3A","497K3B")
#formget <- c("N-1A","N-1A/A","N-14","N-14/A","497K","497K1","497K2","497K3A","497K3B","NSAR-A","NSAR-B","N-Q","N-PX")
#formget <- NULL
formget <- c("N-1A")

formget_collapse <- paste("'",formget,"'",sep="")
formget_collapse <- paste(formget_collapse,collapse=",")
formget_collapse <- paste("(",formget_collapse,")",sep="")

yr_qtr_comb <- expand.grid(yr = seq(startyear, endyear, 1), qtr = seq(1, 4, 1))

yr_qtr_comb <- yr_qtr_comb[order(yr_qtr_comb[,"yr"],yr_qtr_comb[,"qtr"]),]
row.names(yr_qtr_comb) <- seq(nrow(yr_qtr_comb))

yr_qtr_comb[,"qtr"] <- ifelse((yr_qtr_comb[,"yr"]==startyear & yr_qtr_comb[,"qtr"] < startqtr),NA,yr_qtr_comb[,"qtr"])
yr_qtr_comb[,"qtr"] <- ifelse((yr_qtr_comb[,"yr"]==endyear & yr_qtr_comb[,"qtr"] > endqtr),NA,yr_qtr_comb[,"qtr"])

yr_qtr_comb <- yr_qtr_comb[(!is.na(yr_qtr_comb[,"qtr"])),]
row.names(yr_qtr_comb) <- seq(nrow(yr_qtr_comb))

#Check to see if output directory exists.  If not, create it.
create_directory(output_directory,remove=1)


###############################################################################
cat("SECTION: SQLITE DATABASES", "\n")
###############################################################################

#Check to see if download folder exists.  If not, create it.
index_folder_path <- paste(output_directory, indexfolder, sep = slash, collapse = slash)  
create_directory(index_folder_path,remove=1)

index_combined_db <- paste(index_folder_path,"\\","index_combined.s3db",sep="")

index_combined_db_tables <- ListTables(index_combined_db)
index_combined_db_fields <- ListFields(index_combined_db)

###############################################################################
cat("Download files \n")
###############################################################################

#Check to see if download folder exists.  If not, create it.
download_folder_path <- paste(output_directory, downloadfolder, sep = slash, collapse = slash)  
create_directory(download_folder_path,remove=1)

filings_all <- ddply(.data=yr_qtr_comb, .variables=c("yr"), 
                     .fun = function(x, input_db, path_output, sub_path_txt, sub_path_header, outfile, forms, address_prefix_http,address_prefix_ftp){
                       
                       #x <- yr_qtr_comb[(yr_qtr_comb[,"yr"]==1993 & yr_qtr_comb[,"qtr"]==1),]
                       #x <- yr_qtr_comb[(yr_qtr_comb[,"yr"]==1994 & yr_qtr_comb[,"qtr"]==1),]   
                       #x <- yr_qtr_comb[(yr_qtr_comb[,"yr"]==2005 & yr_qtr_comb[,"qtr"]==1),]
                       #x <- yr_qtr_comb[(yr_qtr_comb[,"yr"]==2012 & yr_qtr_comb[,"qtr"]==4),]
                       #input_db <- index_combined_db
                       #path_output <- download_folder_path
                       #sub_path_txt <- txtfolder
                       #sub_path_header <- headerfolder
                       #outfile <- outfile
                       #forms <- formget_collapse
                       #address_prefix_http <- address_http
                       #address_prefix_ftp <- address_ftp
                       
                       yr <- unique(x[,"yr"])
                       
                       cat("\n",yr,"\n")
                       
                       #Check to see if yr folder exists.  If not, create it.
                       #cat("\n")
                       yr_folder_path <- paste(path_output, yr, sep = slash, collapse = slash)   
                       create_directory(yr_folder_path,remove=1)
                       
                       #Check to see if output folders exists.  If not, create it.
                       #cat("\n")
                       output_folder_path_txt <- paste(path_output, yr, sub_path_txt, sep = slash, collapse = slash)   
                       create_directory(output_folder_path_txt,remove=1)
                       
                       output_folder_path_header <- paste(path_output, yr, sub_path_header, sep = slash, collapse = slash)   
                       create_directory(output_folder_path_header,remove=1)
                       
                       if(forms=="('')") {
                         
                         cat("All forms","\n")
                         
                         query_filings_yr <- ""   
                         query_filings_yr <- paste(query_filings_yr, "select       *                                          ", sep=" ")
                         query_filings_yr <- paste(query_filings_yr, "from         index_combined                             ", sep=" ")
                         query_filings_yr <- paste(query_filings_yr, "where        yr=", yr, "                                ", sep=" ")
                         query_filings_yr <- paste(query_filings_yr, "and          cik in (select       distinct cik_no_pad   ", sep=" ")   
                         query_filings_yr <- paste(query_filings_yr, "                     from         CIKs_u              ) ", sep=" ")   
                         query_filings_yr <- gsub(" {2,}", " ", query_filings_yr)
                         query_filings_yr <- gsub("^\\s+|\\s+$", "", query_filings_yr)
                         
                       } else {
                         
                         cat("Certain forms","\n")
                         
                         query_filings_yr <- ""   
                         query_filings_yr <- paste(query_filings_yr, "select       *                                          ", sep=" ")
                         query_filings_yr <- paste(query_filings_yr, "from         index_combined                             ", sep=" ")
                         query_filings_yr <- paste(query_filings_yr, "where        yr=", yr, "                                ", sep=" ")
                         query_filings_yr <- paste(query_filings_yr, "and          cik in (select       distinct cik_no_pad   ", sep=" ")   
                         query_filings_yr <- paste(query_filings_yr, "                     from         CIKs_u              ) ", sep=" ")
                         query_filings_yr <- paste(query_filings_yr, "and          form_type in ", forms, "                   ", sep=" ")
                         query_filings_yr <- gsub(" {2,}", " ", query_filings_yr)
                         query_filings_yr <- gsub("^\\s+|\\s+$", "", query_filings_yr)
                         
                       }
                       rm(yr)
                       
                       filings_temp <- data.frame(runsql(query_filings_yr,input_db),stringsAsFactors=FALSE)
                       rm(query_filings_yr)
                       
                       if(nrow(filings_temp)==0) {
                         
                         cat("No Matches","\n")
                         
                         filings_temp2 <- data.frame(matrix(NA, ncol=(ncol(filings_temp)+5), nrow=nrow(filings_temp), 
                                                            dimnames=list(c(), c(colnames(filings_temp),c("accession_number","filepath","file_header","file_txt","file_index_htm")))), 
                                                     stringsAsFactors=FALSE)
                         
                         filings_temp3 <- filings_temp2[,!(colnames(filings_temp2) %in% c("fullfilename_txt","fullfilename_htm"))]
                         
                       } else {
                         
                         cat("Matches","\n")
                         
                         filings_temp2 <- data.frame(filings_temp,accession_number=NA,filepath=NA,
                                                     file_header=NA,file_txt=NA,file_index_htm=NA,stringsAsFactors=FALSE)
                         
                         filings_temp2[,"file_txt"] <- gsub(".*/", "", filings_temp2[,"fullfilename_txt"])
                         filings_temp2[,"file_index_htm"] <- gsub(".*/", "", filings_temp2[,"fullfilename_htm"])
                         filings_temp2[,"accession_number"] <- gsub("-index.htm", "", filings_temp2[,"file_index_htm"])
                         
                         filings_temp2[,"file_header"] <- paste(filings_temp2[,"accession_number"],
                                                                ".hdr.sgml",
                                                                sep="")
                         
                         filings_temp2[,"filepath"] <- gsub("-", "", filings_temp2[,"accession_number"])
                         
                         filings_temp2[,"filepath"] <- paste("edgar/data",
                                                             filings_temp2[,"cik"],
                                                             filings_temp2[,"filepath"],sep="/")
                         
                         filings_temp3 <- filings_temp2[,!(colnames(filings_temp2) %in% c("fullfilename_txt","fullfilename_htm"))]
                         
                         #Get name of all txt files already downloaded
                         old_txt <- data.frame(file=list.files(output_folder_path_txt),stringsAsFactors=FALSE)
                         old_txt2 <- ddply(.data=old_txt, .variables=c("file"), .fun = function(x,folder){
                           
                           filepath <- paste(folder,x,sep="\\")
                           output <- data.frame(filepath=filepath,file.info(filepath),stringsAsFactors=FALSE)
                           
                         }, folder=output_folder_path_txt, 
                         .progress = "none", .inform = FALSE, .parallel = FALSE, .paropts = NULL, .id = NA)
                         
                         rm(old_txt)
                         
                         old_header <- data.frame(file=list.files(output_folder_path_header),stringsAsFactors=FALSE)
                         old_header2 <- ddply(.data=old_header, .variables=c("file"), .fun = function(x,folder){
                           
                           filepath <- paste(folder,x,sep="\\")
                           output <- data.frame(filepath=filepath,file.info(filepath),stringsAsFactors=FALSE)
                           
                         }, folder=output_folder_path_header, 
                         .progress = "none", .inform = FALSE, .parallel = FALSE, .paropts = NULL, .id = NA)
                         
                         rm(old_header)
                         
                         files_to_download <- data.frame(filepath=filings_temp3[,"filepath"],
                                                         fullfilename_txt=filings_temp3[,"file_txt"],
                                                         #exists_txt=NA,
                                                         already_downloaded_txt=NA,
                                                         fullfilename_header=filings_temp3[,"file_header"],
                                                         #exists_header=NA,
                                                         already_downloaded_header=NA,
                                                         stringsAsFactors=FALSE)
                         
                         files_to_download2 <- files_to_download
                         
                         #checks to see what files on the current index listing are not in the directory
                         files_to_download2[,"already_downloaded_txt"] <- ifelse(files_to_download2[,"fullfilename_txt"] %in% old_txt2[,"file"], 1, 0)
                         files_to_download2[,"already_downloaded_header"] <- ifelse(files_to_download2[,"fullfilename_header"] %in% old_header2[,"file"], 1, 0)
                         
                         files_to_download_trim <- files_to_download2[(files_to_download2[,"already_downloaded_txt"]==0 | 
                                                                         files_to_download2[,"already_downloaded_header"]==0) ,]
                         
                         filings_downloaded <- ddply(.data=files_to_download_trim, .variables=c("filepath","fullfilename_txt","fullfilename_header"), 
                                                     .fun = function(y,sub_path_output_txt,sub_path_output_header,address_prefix_ftp,address_prefix_http){
                                                       
                                                       #y <- files_to_download_trim[1,]
                                                       #sub_path_output_txt <- output_folder_path_txt
                                                       #sub_path_output_header <- output_folder_path_header
                                                       #address_prefix_ftp <- address_prefix_ftp
                                                       #address_prefix_http <- address_prefix_http
                                                       
                                                       filepath <- unique(y[,"filepath"])
                                                       file_txt <- unique(y[,"fullfilename_txt"])
                                                       flag_txt <- unique(y[,"already_downloaded_txt"])
                                                       file_header <- unique(y[,"fullfilename_header"])
                                                       flag_header <- unique(y[,"already_downloaded_header"])
                                                       
                                                       if(flag_txt==0) {
                                                         
                                                         fileout_txt <- paste(sub_path_output_txt,file_txt,sep=slash)
                                                         filepath_http <- paste(address_prefix_http,filepath,"/",sep="")
                                                         filepath_ftp <- paste(address_prefix_ftp,filepath,"/",sep="")
                                                         
                                                         #cat(fileout_txt,"\n")
                                                         
                                                         if (file_check_http(filepath_http,file_txt)) {
                                                           
                                                           #cat("Exists on HTTP mirror","\n")
                                                           
                                                           download.file(paste(filepath_http,file_txt,sep=""),  fileout_txt, quiet = TRUE, mode = "wb",cacheOK = TRUE)
                                                           
                                                         } else if (file_check_ftp(filepath_ftp,file_txt)) {
                                                           
                                                           #cat("Exists on FTP mirror","\n")
                                                           
                                                           download.file(paste(filepath_ftp,file_txt,sep=""), fileout_txt, quiet = TRUE, mode = "wb",cacheOK = TRUE)
                                                           
                                                         } else {
                                                           
                                                           #cat("Doesn't Exists on either mirror","\n")
                                                           
                                                         }
                                                         
                                                         rm(fileout_txt,filepath_http,filepath_ftp)
                                                       } 
                                                       
                                                       if(flag_header==0) {
                                                         
                                                         fileout_header <- paste(sub_path_output_header,file_header,sep=slash)
                                                         filepath_http <- paste(address_prefix_http,filepath,"/",sep="")
                                                         filepath_ftp <- paste(address_prefix_ftp,filepath,"/",sep="")
                                                         
                                                         #cat(fileout_header,"\n")
                                                         
                                                         if (file_check_http(filepath_http,file_header)) {
                                                           
                                                           #cat("Exists on HTTP mirror","\n")
                                                           
                                                           download.file(paste(filepath_http,file_header,sep=""), fileout_header, quiet = TRUE, mode = "wb",cacheOK = TRUE)
                                                           
                                                         } else if (file_check_ftp(filepath_ftp,file_header)) {
                                                           
                                                           #cat("Exists on FTP mirror","\n")
                                                           
                                                           download.file(paste(filepath_ftp,file_header,sep=""), fileout_header, quiet = TRUE, mode = "wb",cacheOK = TRUE)
                                                           
                                                         } else {
                                                           
                                                           #cat("Doesn't Exists on either mirror","\n")
                                                           
                                                         }
                                                         
                                                         rm(fileout_header,filepath_http,filepath_ftp)
                                                         
                                                       } 
                                                       
                                                       rm(filepath,file_txt,flag_txt,file_header,flag_header)
                                                       
                                                     },
                                                     sub_path_output_txt=output_folder_path_txt,sub_path_output_header=output_folder_path_header,
                                                     address_prefix_ftp=address_prefix_ftp, address_prefix_http=address_prefix_http, 
                                                     .progress = "none",.inform = FALSE, .drop = TRUE, .parallel = FALSE, .paropts = NULL)
                         
                         
                         rm(old_txt2,old_header2,files_to_download,files_to_download_trim,filings_downloaded)
                         
                       }
                       
                       write.table(filings_temp3,file=paste(yr_folder_path,outfile,sep="\\"),na="",sep=",",quote=TRUE,row.names=FALSE,append=FALSE)
                       
                       rm(yr_folder_path,output_folder_path_txt,output_folder_path_header)
                       rm(filings_temp,filings_temp2)
                       
                       return(filings_temp3)
                       
                     },
                     input_db=index_combined_db, path_output=download_folder_path, sub_path_txt=txtfolder, sub_path_header=headerfolder,
                     outfile=outfile, forms=formget_collapse, address_prefix_http=address_http, address_prefix_ftp=address_ftp,
                     .progress = "text",.inform = FALSE, .drop = TRUE, .parallel = FALSE, .paropts = NULL)


###############################################################################
cat("Output Combined Files \n")
###############################################################################

write.table(filings_all,file=paste(download_folder_path,"\\",outfile_comb,sep=""), append=FALSE, na="NA", 
            sep = ",", quote = TRUE,dec = ".",  qmethod = "double", col.names=TRUE, row.names = FALSE)
