 #!/usr/bin/perl

# $Id: Daughdrill_read_filings_Section_Number.plx;
# $Revision: 1 $
# $HeadURL: 1 $
# $Source: /Perl/Daughdrill_read_filings_Section_Number.plx $
# $Date: 10.30.2012 $
# $Author: S. Brad Daughdrill $

#Pragmata
use 5.014;    #this enables strict
use warnings;

use vars qw/ $VERSION /;
$VERSION = '1.00';

#use re 'debug';
#use diagnostics;

#Modules
use English qw(-no_match_vars);
use Readonly;
use Benchmark;

#use Mods;
#use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
#use Carp qw( croak );
#use Fcntl;
#use HTML::Formatter;      #get the HTML-Format package from the package manager.
#use HTML::TreeBuilder;    #get the HTML-TREE from the package manager
#use HTML::FormatText;
#use Net::FTP;
#use Tie::File;

use List::MoreUtils qw(apply pairwise uniq);
use PadWalker qw();

my $print_err  = "Cannot print:\t";


my @coins_with_space = ();
@coins_with_space = ("Quarter     ","      Dime","       Nickel         ","Penny");


print_list_with_err( q{@coins_with_space}, q{$print_err} );

@coins_with_space = map { trim($_)   } @coins_with_space;

print_list_with_err( q{@coins_with_space}, q{$print_err} );



#=====================================================================;
#SUBROUTINES;
#=====================================================================;
# Perl trim function to remove whitespace from the start and end of the string
sub trim {
    my $string = shift;
    $string =~ s/^\s+//xms;
    $string =~ s/\s+$//xms;
    return $string;
}

# Left trim function to remove leading whitespace
sub ltrim {
    my $string = shift;
    $string =~ s/^\s+//xms;
    return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim {
    my $string = shift;
    $string =~ s/\s+$//xms;
    return $string;
}

# Used in print functions
sub peek_above {
    my $name_peek_above = shift;
    return PadWalker::peek_my(2)->{$name_peek_above}
      // PadWalker::peek_our(2)->{$name_peek_above};
}

# Print variable with error messages
sub print_var_with_err {
    my ( $a, $b ) = @_;

    #use vars qw($a_eval $b_eval);
    #$a_eval = ${ peek_above $a};
    #$b_eval = ${ peek_above $b};
    my $a_eval = ${ peek_above $a};
    my $b_eval = ${ peek_above $b};
    print $a . qq{:\n} . $a_eval . qq{\n} or croak( $b_eval . $ERRNO );
    return;
}

# Print list with error messages
sub print_list_with_err {
    my ( $c, $d ) = @_;
    my @c_eval = @{ peek_above $c};
    my $d_eval = ${ peek_above $d};
    while ( my ( $index, $elem ) = each @c_eval ) {
        say $c . q{[} . $index . qq{]:\n} . $elem . qq{\n}
          or croak( $d_eval . $ERRNO );
    }
    return;
}
