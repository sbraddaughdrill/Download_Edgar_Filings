use warnings;
#use strict;
my $codedirect="C:\\Users\\bdaughdr\\Google Drive\\Dropbox\\Dropbox\\Research\\3rd-Year_Paper\\Perl";                        # Office 2;
my $file = "test1.txt";
my $slash='\\';







open(my $fh, "<","$codedirect$slash"."$file") or die "Error opening < input.txt: $!\n";

my $this_line = "";
my $do_next = 0;

while(<$fh>) {
    my $last_line = $this_line;
    $this_line = $_;

    if ($this_line =~ /XXX/) {
        print $last_line unless $do_next;
        print $this_line;
        $do_next = 1;
    } else {
        print $this_line if $do_next;
        $last_line = "";
        $do_next = 0;
    }
}
close ($fh);