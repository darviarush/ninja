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

sub i { shift()->{i} }
sub config { shift()->{config} }
sub project { my ($self) = @_; $self->{config}->{project}->{$self->pwd} }
sub root { shift()->{root} }
sub selectors { shift()->{selectors} }
sub jinnee { shift()->{jinnee} }
sub area { shift()->{area} }
sub position { shift()->{position} }


sub construct {
	my ($self) = @_;
	
	my $config = $self->config->load;
	
	use Tcl;
	$self->{i} = my $i = Tcl->new;
	$i->SetVar("argv", Tcl::GLOBAL_ONLY);
	$i->SetVar("tcl_interactive", 0, Tcl::GLOBAL_ONLY);
	$i->Init;

	$i->EvalFile("lib/Ninja/tk/main-window.tcl");

	::msg "config load", $config;
	
	# $i->CreateCommand("::perl::config", sub {
		# my @path = split /./, $_[0];
		# my $c = $config;
		
		# if(@_ == 1) {
			# for(@path) {
				# if(ref $c eq "HASH") { $c = $c->{$_} }
				# elsif(ref $c eq "ARRAY") { $c = $c->[$_] }
				# else { return undef; }
			# }
			
			# return $c;
		# }
		
		# my $last = pop @path;
		# for(@path) {
			# if(ref $c eq "HASH") { $c = $c->{$_} }
			# elsif(ref $c eq "ARRAY") { $c = $c->[$_] }
			# else { return undef; }
		# }
		# return;
	# });

	$i->icall(qw/wm geometry ./, $config->{geometry}) if $config->{geometry};
	my @sec = qw/packages classes categories methods/;
	do { $i->icall(".$sec[$_].filter", qw/insert end/, $config->{sections}{filters}[$_]) for 0..3 } if $config->{sections}{filters};
	do { $i->icall(qw/.sections paneconfigure/, ".$sec[$_]", "-width", $config->{sections}{widths}[$_]) for 0..2 } if $config->{sections}{widths};
	$i->icall(qw/.sections configure -height /, $config->{sections}->{height}) if $config->{sections}->{height};
	
	#my $sigint = $SIG{INT};
	#$SIG{INT} = sub { $i->Eval("destroy ."); $sigint->(@_) };
	
	$i->CreateCommand("::perl::on_window_destroy", sub {
		$config->{geometry} = $i->icall(qw/wm geometry ./);
		$config->{sections}{filters}[$_] = $i->Eval(".$sec[$_].filter get") for 0..3;
		$config->{sections}{widths}[$_] = $i->Eval("winfo width .$sec[$_]") for 0..2;
		$config->{sections}->{height} = $i->Eval("winfo height .sections");
		::msg "config save", $config;
		$config->save;
	});
	
	#$self->{selectors} = Ninja::SelectorBoxes->new(main => $self);
	
	$i->Eval("tkwait window .");
	
	return $self;
	
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

sub close {
	my ($self) = @_;
	
	return $self if !defined $self or $self->{closed};
	$self->{closed} = 1;
	
	
	my $config = $self->config;
	my $sections = $self->{sections};

    $config->{root}->{geometry} = $self->i->Eval("wm geometry .") || "350x250+300+300";
    
    $config->{sections}->{height} = $sections->height;

    $config->{sections}->{widths} = [map { $_->width } @{$self->{frames}}[0..2]];
	$config->{sections}->{filters} = [
		$self->selectors->{package_filter}->get,
		$self->selectors->{class_filter}->get,
		$self->selectors->{category_filter}->get,
		$self->selectors->{method_filter}->get,
	];
	
	my ($section, $idx) = $self->selectors->who;
	$config->{project}{$self->pwd} = {
		selectors => {
			package => scalar $self->selectors->packages->curselection,
			class => scalar $self->selectors->classes->curselection,
			category => scalar $self->selectors->categories->curselection,
			method => scalar $self->selectors->methods->curselection,
		}
	};
	
	
	$self->config->save;
	$self->root->destroy;
	
	$self
}

sub pwd {
	use Cwd qw();
	Cwd::cwd()
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