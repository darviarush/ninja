#!/usr/bin/env perl

use common::sense;
use open qw/:std :utf8/;

#require Tk::ErrorDialog;

use lib 'lib';
use Ninja::Ext::Runtime;
use Ninja::MainWindow;

my $class_lang = "Jinnee";
#my $class_lang = "Ninja::Jinnee::Perl";
eval "require $class_lang";
die $@ if $@;

Ninja::MainWindow->new(jinnee => $class_lang->new)->construct;
