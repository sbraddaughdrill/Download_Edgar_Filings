#!/usr/bin/perl

# $Id: XXX.plx;
# $Revision: 1 $
# $HeadURL: 1 $
# $Source: /Perl/XXX.plx $
# $Date: 10.30.2012 $
# $Author: daugh016 $
use 5.014;    #this enables strict
use warnings;

use vars qw/ $VERSION /;
$VERSION = '1.00';

use English qw(-no_match_vars);
use PadWalker qw(peek_my peek_our peek_sub closed_over var_name);
use Readonly;

my $print_err = "Cannot print:\t";

my $var_test  = 'This is a test variable';
my @list_test = qw(This is a test list);

#print_var_with_err( "\$var_test", "\$print_err" );
#print_list_with_err( "\@list_test", "\$print_err" );

# Print variable with error messages
#sub print_var_with_err {
#
#    my ( $a, $b ) = @_;
#    my $a_eval = eval $a;
#    my $b_eval = eval $b;
#    print $a . qq{:\n} . $a_eval . qq{\n} or croak( $b_eval . $ERRNO );
#    return;
#}

# Print list with error messages
#sub print_list_with_err {
#
#    my ( $c, $d ) = @_;
#    my @c_eval = eval "$c";
#    my $d_eval = eval $d;
#    while ( my ( $index, $elem ) = each @c_eval ) {
#        say $c . q{[} . $index . qq{]:\n} . $elem . qq{\n}
#          or croak( $d_eval . $ERRNO );
#    }
#    return;
#}

print_var_with_err2('$var_test', '$print_err' );
print_list_with_err2('@list_test', '$print_err' );

sub peek_above {
    my $name = shift;

    #PadWalker::peek_my(2)->{$name} // PadWalker::peek_our(2)->{$name};
    return PadWalker::peek_my(2)->{$name} // PadWalker::peek_our(2)->{$name};
}

# Print variable with error messages
sub print_var_with_err2 {
    my ( $a, $b ) = @_;
    my $a_eval = ${ peek_above $a};
    my $b_eval = ${ peek_above $b};
    print $a . qq{:\n} . $a_eval . qq{\n} or croak( $b_eval . $ERRNO );
    return;
}

# Print list with error messages
sub print_list_with_err2 {
    my ( $c, $d ) = @_;
    my @c_eval = @{ peek_above $c};
    my $d_eval = ${ peek_above $d};
    while ( my ( $index, $elem ) = each @c_eval ) {
        say $c . q{[} . $index . qq{]:\n} . $elem . qq{\n}
          or croak( $d_eval . $ERRNO );
    }
    return;
}

#print_var_with_err3( q[$var_test], $var_test, q[$print_err], $print_err );
#print_list_with_err3( q[@list_test], \@list_test, q[$print_err], $print_err );

# Print variable with error messages
#sub print_var_with_err3 {
#    my ( $a, $a_eval, $b, $b_eval ) = @_;
#    print $a . qq{:\n} . $a_eval . qq{\n} or croak( $b_eval . $ERRNO );
#    return;
#}

# Print list with error messages
#sub print_list_with_err3 {
#    my ( $c, $c_eval, $d, $d_eval ) = @_;
#    while ( my ( $index, $elem ) = each @$c_eval ) {
#        say $c . q{[} . $index . qq{]:\n} . $elem . qq{\n}
#          or croak( $d_eval . $ERRNO );
#    }
#    return;
#}
