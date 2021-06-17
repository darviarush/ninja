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

sub sec {
	my $f1 = $root->Frame;
	my $list = $f1->Listbox;
	$list->pack(qw/-fill both -expand 1/);
	my $entry = $f1->Entry;
	$entry->pack(-side => 'bottom');
	$sections->add($f1);
	return $list, $entry;
}

my ($rank, $rank_filter) = sec();
my ($classes, $class_filter) = sec();
my ($categories, $category_filter) = sec();
my ($methods, $method_filter) = sec();


my $text = $root->Text;
$text->pack(-side => 'top');
$sections->pack(-side => 'top');

$main->add($sections, $text);
$main->pack(-fill=>'both', -expand=>1);

MainLoop;
