#!/usr/bin/env perl

use common::sense;
use Tk;
use DDP {class=>{expand=>10_000}};

# Инициализация конфига
my $config;
use JSON::XS;
my $json = JSON::XS->new->canonical->allow_nonref->pretty(1);
my $config_path = "$ENV{HOME}/.config/ninja-lang-editor.json";
load_config();


# Окно
my $root = MainWindow->new(-title => "Ninja");


my $menu = $root->Menu;
$root->configure(-menu => $menu);

my $file_menu = $menu->Menu();
$menu->cascade(-label => 'Файл', -menu => $file_menu);

$file_menu->command(-label => 'Открыть', -command => sub {});
$file_menu->separator;
$file_menu->command(-label => 'Завершить', -command => sub { shift->quit() });

my $main = $root->Panedwindow(-orient => 'vertical');
my $sections = $main->Panedwindow(-orient => 'horizontal');
my $text = $main->Text;
my @frames;

sub sec {
	my $f1 = $sections->Frame();
	my $list = $f1->Listbox;
	$list->pack(-side => 'top', -fill => 'both', -expand => 1);
	my $entry = $f1->Entry;
	$entry->pack(-side => 'bottom', -fill => 'both');
    my $i = @{$sections->panes};
    my $width = $config->{sections}{widths}[$i];
	$sections->add($f1, $width? (-width => $width): ());
    push @frames, $f1;
	return $list, $entry;
}

my ($rank, $rank_filter) = sec();
my ($classes, $class_filter) = sec();
my ($categories, $category_filter) = sec();
my ($methods, $method_filter) = sec();

#$sections->pack(-side => 'top');
#$text->pack(-side => 'top');#,-fill=>'both', -expand=>1);

$main->add($sections);
$main->add($text);
$main->pack(-fill=>'both', -expand=>1);

# Тулбар
my $f = $root->Frame();
my $position = $f->Label(-text => "Line 1, Column 1");
$position->pack(-side=>'left');
$f->pack(-side => 'bottom');

#$root->iconify()
$root->protocol(WM_DELETE_WINDOW => sub { save_config(); $root->destroy });

# *** Конфигурация
$root->geometry($config->{root}->{geometry}) if $config->{root}->{geometry};
$sections->configure(-height=>$config->{sections}->{height}) if $config->{sections}->{height};

# ***

# загружаем конфиг из папки пользователя
sub load_config {
    if(-f $config_path) {
        open my $f, $config_path or do { warn "$config_path: $!"; return };
        read $f, $_, -s $f;
        $config = $json->decode($_);
        close $f;
    }
}

sub save_config {
    if(!-e $config_path) {
        mkdir $`, 0644 while $config_path =~ /\//g;
        undef $!;
    }

    $config = {};

    $config->{root}->{geometry} = $root->geometry;
    
    $config->{sections}->{height} = $sections->height;
    pop @frames;
    $config->{sections}->{widths} = [map { $_->width } @frames];
    

    open my $f, ">", $config_path or do { warn "$config_path: $!"; return };
    print $f $json->encode($config);
    close $f;
}

my $project_path = "./.ninja.pl";
sub load_project {
	if(-f $project_path) {
        require $project_path;
        
    }
}



MainLoop;