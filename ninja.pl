#!/usr/bin/env perl

use common::sense;
use Tk;


my $root = MainWindow->new(-title => "Ninja");
# $root->Label(-text => 'Hello, world!')->pack;
# $root->Button(
#     -text    => 'Quit',
#     -command => sub { exit },
# )->pack;

my $menu = $root->Menu;
$root->configure(-menu => $menu);

my $file_menu = $menu->Menu();
$menu->cascade(-label => 'Файл', -menu => $file_menu);

$file_menu->command(-label => 'Открыть', -command => sub {});
$file_menu->separator;
$file_menu->command(-label => 'Завершить', -command => sub {exit});

my $main = $root->Panedwindow(qw/-orient vertical/);
my $sections = $root->Panedwindow(qw/-orient horizontal/);

sub sec {
	my $f1 = $root->Frame;
	my $list = $f1->Listbox;
	$list->pack(-side => 'top', -fill => 'both', -expand => 1);
	my $entry = $f1->Entry;
	$entry->pack(-side => 'bottom', -fill => 'both');
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

my $f = $root->Frame;
my $position = $f->Label(-text => "Line 1, Column 1");
$position->pack(-side=>'left');
$f->pack(-side => 'bottom', -fill=>'both');

MainLoop;



# ***

sub load_project {
	
}