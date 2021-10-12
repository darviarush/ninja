#!/usr/bin/env perl

use common::sense;
use open qw/:std :utf8/;

use lib 'lib';
use Ninja::Ext::Runtime;
use Ninja::MainWindow;


my $cf = -e "./.ninjarc"? require("./.ninjarc"): {
	jn => ["Jinnee",
		INC => ["src"],
	],
	pl => ["Ninja::Jinnee::Perl",
		INC => ["lib"],
	],
	default => 'jn',
};


my ($class_lang, %args) = @{$cf->{$ARGV[0] // $cf->{default}}};

eval "require $class_lang";
die $@ if $@;

Ninja::MainWindow->new(jinnee => $class_lang->new(%args))->construct;
