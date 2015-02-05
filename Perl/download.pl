#!/usr/bin/perl
use LWP;
use HTTP::Request;
sub get_http
{
    my $url = shift;
    my $request = HTTP::Request->new(GET => $url);
    my $response = $ua->request($request);
    if (!$response->is_success)
    {
        print STDERR "GET '%s' failed: %s\n",
		$url, $response->status_line;
        return undef;
	}
    return $response->content;
}
# user agent object for handling HTTP requests
my $ua = LWP::UserAgent->new;

# if you only want a portion of the filing, un-comment the next line
#$ua->max_size(50000);  # 50k byte limit

######################### write dir , use "\\" and not "\", for example: "C:\\temp"
$write_dir = "C:\\temp";
######################### write dir 

######################### filename with urls (put in same directory as script) 
open dlthis, "c_10K_list.txt" or die $!;
######################### filename with urls (put in same directory as script)

######################### log
open LOG , ">download_log.txt" or die $!;
######################### log

my @file = <dlthis>;

foreach $line (@file) { 
	#CIK, filename, blank is not used (included because it will capture the newline)
	($CIK, $get_file, $blank) = split (",", $line);
	$get_file = "http://www.sec.gov/Archives/" . $get_file;
	$_ = $get_file;
	
	if ( /([0-9|-]+).txt/ ) {
		$filename = $write_dir . "/" . $CIK . ".txt";
		open OUT, ">$filename" or die $!;
		print "file $CIK \n";
		
		my $request = HTTP::Request->new(GET => $get_file);
		my $response =$ua->get($get_file );
		$p = $response->content;
		if ($p) {
			print OUT $p;
			close OUT;
			} else {
			#error logging
			print LOG "error in $filename - $CIK \n" ;
		}
	}  
}
close LOG;
#ignore the line below (inserted by Forum engine because it wants to 'close' a similar tag used to load the file)
</dlthis>