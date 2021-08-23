package Ninja::MainWindow;
# Главное окно проекта 

use common::sense;

use Tk;
use Tk::Text;
use Tk::MsgBox;

use Ninja::Config;
use Ninja::SelectorBoxes;
use Ninja::MethodArea;
use Ninja::Menu;

sub new {
	my $cls = shift;
	bless {
		config => Ninja::Config->new(path => "$ENV{HOME}/.config/ninja-lang-editor.json"),
		@_,
	}, ref $cls || $cls;
}

sub config { shift()->{config} }
sub root { shift()->{root} }
sub selectors { shift()->{selectors} }
sub jinnee { shift()->{jinnee} }
sub area { shift()->{area} }
sub position { shift()->{position} }

sub evt_select_all {
	my ($entry) = @_;
	$entry->selectionRange(0, "end");
	$entry->icursor("end");
}

sub sec {
	my ($self) = @_;
	my $sections = $self->{sections};
	my $f1 = $sections->Frame();
		
	my $list = $f1->Scrolled("Listbox", -scrollbars=>"oe", 
		-exportselection => 0,
	);
	$list->Subwidget("yscrollbar")->configure(-width=>10);
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

	$self->{menu} = Ninja::Menu->new(menu=>$menu, main=>$self)->construct;
	
	my $main = $root->Panedwindow(-orient => 'vertical');
	$self->{sections} = my $sections = $main->Panedwindow(-orient => 'horizontal');
	my $text = $main->Scrolled("Text", -scrollbars=>"osoe",
		-wrap => "word",
	);
	$text->Subwidget("yscrollbar")->configure(-width=>10);
	$text->Subwidget("xscrollbar")->configure(-width=>10);
	my @frames;

	$self->{selectors} = my $boxes = Ninja::SelectorBoxes->new(main => $self);

	($boxes->{packages}, $boxes->{package_filter}, $frames[0]) = $self->sec();
	($boxes->{classes}, $boxes->{class_filter}, $frames[1]) = $self->sec();
	($boxes->{categories}, $boxes->{category_filter}, $frames[2]) = $self->sec();
	($boxes->{methods}, $boxes->{method_filter}, $frames[3]) = $self->sec();

	$self->{frames} = [@frames];
	
	$main->add($sections);
	$main->add($text);
	$main->pack(-fill=>'both', -expand=>1);

	$self->{area} = Ninja::MethodArea->new(area => $text, main => $self)->construct;

	# Тулбар
	my $f = $root->Frame();
	$self->{position} = my $position = $f->Label(-text => "Line 1, Column 1", -justify => 'left');
	$position->pack(-side=>'left');
	$f->pack(-side => 'bottom');

	#$root->iconify()
	$root->protocol(WM_DELETE_WINDOW => $SIG{INT} = sub { $self->close });

	# *** Конфигурация
	$root->geometry($self->config->{root}->{geometry}) if $self->config->{root}->{geometry};
	$sections->configure(-height=>$self->config->{sections}->{height}) if $self->config->{sections}->{height};

	$boxes->construct;

	MainLoop;
}


sub DESTROY {
	my ($self) = @_;
	$self->close;
}

sub close {
	my ($self) = @_;
	
	return $self if $self->{closed};
	$self->{closed} = 1;
	
	
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

# sub Tk::Error {
	# my ($widget,$error,@locations) = @_;
	
	
	# utf8::decode($error);
	# print "Tk::Error: ", utf8::is_utf8($error)? 'yes': 'no', " ", $error;
	
	# ::p($error);
	# ::p(@locations);
	
	
# }

sub errorbox {
	my ($self, $error, @args) = @_;
		
	$self->msgbox($error, -icon => "error", -title => "error", @args);
}

sub msgbox {
	my ($self, $message, @args) = @_;
	
	$self->root->MsgBox(
		-icon => "info", 
		-title => "message", 
		-type => "ok", 
		#-detail => "hi!", 
		-message => $message,
		@args
	)->Show; 
	
	$self
}

1;