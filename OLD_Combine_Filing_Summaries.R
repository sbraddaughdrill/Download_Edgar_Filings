# TODO: Add comment
# 
# Author:  Brad
# File:    Combine_Filing_Summaries.R
# Version: 1.0
# Date:    02.5.2014
# Purpose: This program combines all the filing summaries
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

#source(file=paste(function_directory,"functions_db.R",sep="\\"),echo=FALSE)
#source(file=paste(function_directory,"functions_statistics.R",sep="\\"),echo=FALSE)
#source(file=paste(function_directory,"functions_text_analysis.R",sep="\\"),echo=FALSE)
source(file=paste(function_directory,"functions_utilities.R",sep="\\"),echo=FALSE)

###############################################################################
# LIBRARIES;
cat("SECTION: LIBRARIES", "\n")
###############################################################################

#Load External Packages
external_packages <- c("gdata","plyr")
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

#downloadfolder <- "N-1"
#downloadfolder <- "DEF 14A"
#downloadfolder <- "MF_All"
#downloadfolder <- "MF_SemiAnnual_Reports"
#downloadfolder <- "MF_Annual_Reports"
downloadfolder <- "MF_Shareholder_Reports_N-CSR-A"
#downloadfolder <- "MF_Shareholder_Reports_N-CSRS-A"
#downloadfolder <- "MF_Shareholder_Reports_N-CSR"
#downloadfolder <- "MF_Shareholder_Reports_N-CSRS"

#The file that will contain the filings you want to download.
infile <- "filings.csv"

outfile <- "filings_list_comb.csv"

yr_comb <- as.data.frame(seq(startyear, endyear, 1),
                         stringsAsFactors=FALSE)
colnames(yr_comb)[1] <- "yr"

#yr_comb <- yr_comb[order(yr_comb[,"yr"]),]
#row.names(yr_comb) <- seq(nrow(yr_comb))

#Check to see if output directory exists.  If not, create it.
create_directory(output_directory,remove=1)

#Check to see if download folder exists.  If not, create it.
download_folder_path <- paste(output_directory, downloadfolder, sep = slash, collapse = slash)  
create_directory(download_folder_path,remove=1)


###############################################################################
cat("Combine files \n")
###############################################################################

filings_comb <- ddply(.data=yr_comb, .variables=c("yr"), 
                      .fun = function(x, path_output, infile){
                        
                        #x <- yr_comb[(yr_comb[,"yr"]==1993),]
                        #x <- yr_comb[(yr_comb[,"yr"]==1994),]   
                        #x <- yr_comb[(yr_comb[,"yr"]==2005),]
                        #x <- yr_comb[(yr_comb[,"yr"]==2012),]
                        #path_output <- download_folder_path
                        #infile <- infile
                        
                        yr <- unlist(x)
                        
                        cat("\n",yr,"\n")
                        
                        #Check to see if yr folder exists.  If not, create it.
                        #cat("\n")
                        yr_folder_path <- paste(path_output, yr, sep = slash, collapse = slash)   
                        create_directory(yr_folder_path,remove=1)
                        
                        filings_temp <- read.table(file=paste(yr_folder_path,"\\",infile,sep=""), header = TRUE, na.strings="NA",stringsAsFactors=FALSE, 
                                                   sep = ",", quote = "\"",dec = ".", fill = TRUE, comment.char = "")
                        
                        if(nrow(filings_temp)==0) {
                          
                          cat("No Matches","\n")
                          
                          filings_temp2 <- data.frame(matrix(NA, ncol=(ncol(filings_temp)+5), nrow=nrow(filings_temp), 
                                                             dimnames=list(c(), 
                                                                           c(colnames(filings_temp),
                                                                                      c("accession_number","filepath","file_header","file_txt","file_index_htm")))), 
                                                                           stringsAsFactors=FALSE)
                                                             
                          filings_temp3 <- filings_temp2[,!(colnames(filings_temp2) %in% c("fullfilename_txt","fullfilename_htm"))]
                          
                        } else {
                          
                          cat("Matches","\n")
                          
                          
                          filings_temp2 <- data.frame(filings_temp,
                                                      accession_number=NA,
                                                      filepath=NA,
                                                      file_header=NA,
                                                      file_txt=NA,
                                                      file_index_htm=NA,
                                                      stringsAsFactors=FALSE)
                          
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
                          
                        }
                          
                        return(filings_temp3)
                        
                      },
                      path_output=download_folder_path, infile=infile, 
                      .progress = "text",.inform = TRUE, .drop = TRUE, .parallel = FALSE, .paropts = NULL)


###############################################################################
cat("Output Combined Files \n")
###############################################################################

write.table(filings_comb,file=paste(download_folder_path,"\\",outfile,sep=""), append=FALSE, na="NA", 
           sep = ",", quote = TRUE,dec = ".",  qmethod = "double", col.names=TRUE, row.names = FALSE)