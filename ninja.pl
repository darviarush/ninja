#!/usr/bin/env perl

use common::sense;
use open qw/:std :utf8/;

use DDP {class=>{expand=>10_000}};
use Carp;

# в Tk работать не будет - перекрывается своим обработчиком
$SIG{__DIE__} = sub { print Carp::longmess(@_) };

#require Tk::ErrorDialog;

use lib 'lib';
use Ninja::MainWindow;

use Jinnee;


Ninja::MainWindow->new(jinnee => Jinnee->new)->construct;

sub msg (@) {
	my $x=shift;
	if(@_) {print "$x: "; p @_; $_[$#_]} else {print "$x\n"; $x}
}

sub msga (@) {
	my $x=shift;
	print "$x: ";
	p @_;
	@_
}

sub trace {
	print Carp::longmess(@_), "\n\n";
}