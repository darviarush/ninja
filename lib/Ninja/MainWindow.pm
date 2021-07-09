package Ninja::MainWindow;
# Главное окно проекта 

use common::sense;

use Tk;

use Ninja::Config;
use Ninja::SelectorBoxes;

sub new {
	my $cls = shift;
	bless {
		config => Ninja::Config->new(path => "$ENV{HOME}/.config/ninja-lang-editor.json"),
		@_,
	}, ref $cls || $cls;
}

sub config {
	my ($self) = @_;
	$self->{config}
}

sub root {
	my ($self) = @_;
	$self->{root}
}

sub selectors {
	my ($self) = @_;
	$self->{selectors}
}

sub evt_select_all {
	my ($entry) = @_;
	$entry->selectionRange(0, "end");
	$entry->icursor("end");
}

sub sec {
	my ($self) = @_;
	my $sections = $self->{sections};
	my $f1 = $sections->Frame();
	
	my $list = $f1->Listbox;
	$list->pack(-side => 'top', -fill => 'both', -expand => 1);
	
	my $entry = $f1->Entry;
	$entry->pack(-side => 'bottom', -fill => 'both');
    
	my $i = @{$sections->panes};
	
	$entry->insert('end', $self->config->{sections}{filters}[$i]);
	$entry->bind('<Control-a>', \&evt_select_all);
	
    my $width = $self->config->{sections}{widths}[$i];
	$sections->add($f1, $width? (-width => $width): ());
    
	return $list, $entry, $f1;
}

sub construct {
	my ($self) = @_;
	
	$self->config->load;
	
	$self->{root} = my $root = MainWindow->new(-title => "Ninja");


	my $menu = $root->Menu;
	$root->configure(-menu => $menu);

	my $file_menu = $menu->Menu();
	$menu->cascade(-label => 'Файл', -menu => $file_menu);

	$file_menu->command(-label => 'Открыть', -command => sub {});
	$file_menu->separator;
	$file_menu->command(-label => 'Завершить', -command => sub { shift->quit() });

	my $main = $root->Panedwindow(-orient => 'vertical');
	$self->{sections} = my $sections = $main->Panedwindow(-orient => 'horizontal');
	my $text = $main->Text;
	my @frames;

	$self->{selectors} = my $boxes = Ninja::SelectorBoxes->new;

	($boxes->{packages}, $boxes->{package_filter}, $frames[0]) = $self->sec();
	($boxes->{classes}, $boxes->{class_filter}, $frames[1]) = $self->sec();
	($boxes->{categories}, $boxes->{category_filter}, $frames[2]) = $self->sec();
	($boxes->{methods}, $boxes->{method_filter}, $frames[3]) = $self->sec();

	$self->{frames} = [@frames];
	
	$main->add($sections);
	$main->add($text);
	$main->pack(-fill=>'both', -expand=>1);

	# Тулбар
	my $f = $root->Frame();
	my $position = $f->Label(-text => "Line 1, Column 1");
	$position->pack(-side=>'left');
	$f->pack(-side => 'bottom');

	#$root->iconify()
	$root->protocol(WM_DELETE_WINDOW => $SIG{INT} = sub { $self->close });

	# *** Конфигурация
	$root->geometry($self->config->{root}->{geometry}) if $self->config->{root}->{geometry};
	$sections->configure(-height=>$self->config->{sections}->{height}) if $self->config->{sections}->{height};

	MainLoop;
}


sub DESTROY {
	my ($self) = @_;
	$self->close;
}

sub close {
	my ($self) = @_;
	my $config = $self->config;
	my $sections = $self->{sections};

    $config->{root}->{geometry} = $self->root->geometry;
    
    $config->{sections}->{height} = $sections->height;

    $config->{sections}->{widths} = [map { $_->width } @{$self->{frames}}[0..2]];
	$config->{sections}->{filters} = [
		$self->selectors->{package_filter}->get,
		$self->selectors->{class_filter}->get,
		$self->selectors->{category_filter}->get,
		$self->selectors->{method_filter}->get,
	];
	
	$self->config->save;
	$self->root->destroy;
	
	$self
}

1;