use common::sense;
use open qw/:std :utf8/;

use DDP;

$\ = "\n";

"sabbc" =~ / a(?<x> b)+ /x;
p my $x=[\@-, \%-, \@+, \%+];

# my $f = "";
# my $x = "abc";

# p my $x = qr/$f/i;

# print $x =~ /$f/i? 1: 0;
# print $x =~ /$f/i? 1: 0;
