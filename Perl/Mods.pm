package Mods;
our $VERSION = 0.14;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Carp qw( croak );
use Fcntl;
use HTML::Formatter;      #get the HTML-Format package from the package manager.
use HTML::TreeBuilder;    #get the HTML-TREE from the package manager
use HTML::FormatText;
use Net::FTP;
use Tie::File;

1;
