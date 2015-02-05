use Data::Dumper;

my $ssh = 'this is a test';
my @ssh2 = qw(this is a test);
print Dumper $ssh;
print Dumper \$ssh;
print Dumper @ssh2;
print Dumper \@ssh2;