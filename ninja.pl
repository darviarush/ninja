#!/usr/bin/env perl

use common::sense;

use DDP {class=>{expand=>10_000}};
use Carp;

$SIG{__DIE__} = sub { die Carp::longmess(@_) };

use lib 'lib';
use Ninja::MainWindow;

use Jinnee;

Ninja::MainWindow->new(jinnee => Jinnee->new)->construct;
