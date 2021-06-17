#!/usr/bin/env perl

use common::sense;
use Tk;


my $root = MainWindow->new(-title => "Ninja");
$root->Label(-text => 'Hello, world!')->pack;
$root->Button(
    -text    => 'Quit',
    -command => sub { exit },
)->pack;


my $main = $root->Panedwindow(qw/-orient vertical/);
my $sections = $root->Panedwindow(qw/-orient horizontal/);

my $class_categories = $root->Listbox;
$class_categories->pack(-side => 'left');
$sections->add($class_categories);

my $classes = $root->Listbox;
$classes->pack(-side => 'left');
$sections->add($classes);

my $method_categories = $root->Listbox;
$method_categories->pack(-side => 'left');
$sections->add($method_categories);

my $methods = $root->Listbox;
$methods->pack(-side => 'left');
$sections->add($methods);

$sections->pack(-side => 'top');
$main->add($sections);

my $text = $root->Text;
$text->pack(-side => 'top');
$main->add($text);

$main->pack(-fill=>'both', -expand=>1);

MainLoop;
