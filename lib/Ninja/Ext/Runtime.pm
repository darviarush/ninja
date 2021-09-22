package Ninja::Ext::Runtime {}

use DDP {class=>{expand=>10_000}};
use Carp;

# в Tk работать не будет - перекрывается своим обработчиком
$SIG{__DIE__} = sub { print STDERR Carp::longmess(@_) };


sub pp ($) {
	my $x = shift;
	p $x;
	$x
}

sub msg (@) {
	my $x=shift;
	unshift(@_, $x), $x = "msg" if ref $x or !defined $x;
	my ($pkg, $file, $line) = caller;
	if(@_) {print STDERR "$file:$line $x: "; p @_; $_[$#_]} else {p $x; $x}
}

sub msga (@) {
	my $x=shift;
	unshift(@_, $x), $x = "msga" if ref $x or !defined $x;
	my ($pkg, $file, $line) = caller;
	print STDERR "$file:$line $x: ";
	p @_;
	@_
}

sub trace {
	print STDERR Carp::longmess(@_), "\n\n";
}

1;