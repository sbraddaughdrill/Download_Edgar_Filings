    use Perl::Critic;
    my $file = test2;
    my $critic = Perl::Critic->new();
    my @violations = $critic->critique($file);
    print @violations;