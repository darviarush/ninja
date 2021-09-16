package Ninja::Ext::Runtime {}

use DDP {class=>{expand=>10_000}};
use Carp;

# в Tk работать не будет - перекрывается своим обработчиком
$SIG{__DIE__} = sub { print Carp::longmess(@_) };


sub pp ($) {
	my $x = shift;
	p $x;
	$x
}

sub msg (@) {
	my $x=shift;
	unshift(@_, $x), $x = "msg" if ref $x or !defined $x;
	if(@_) {print "$x: "; p @_; $_[$#_]} else {p $x; $x}
}

sub msga (@) {
	my $x=shift;
	unshift(@_, $x), $x = "msga" if ref $x or !defined $x;
	print "$x: ";
	p @_;
	@_
}

sub trace {
	print Carp::longmess(@_), "\n\n";
}

1;