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

# PATCH: вызывается при удалении процедуры перла внедрённой в Tcl
sub Tcl::Cmdbase::TRACE_DELETECOMMAND() {}


sub i { shift->{i} }
sub config { shift->{config} }
sub project { my ($self) = @_; $self->{config}->{project}->{$self->pwd} //= {} }
sub jinnee { shift->{jinnee} }
sub menu { shift->{menu} }
sub area { shift->{area} }
sub selectors { shift->{selectors} }

sub construct {
	my ($self) = @_;
	
	my $config = $self->config->load;
	
	use Tcl;
	$self->{i} = my $i = Tcl->new;
	$i->SetVar("argv", Tcl::GLOBAL_ONLY);
	$i->SetVar("tcl_interactive", 0, Tcl::GLOBAL_ONLY);
	$i->Init;

	$i->EvalFile("lib/Ninja/tk/main-window.tcl");

	my $project = $self->project;

	$i->icall(qw/wm geometry ./, $project->{geometry}) if $project->{geometry};
	my @sec = $self->jinnee->sections;
	do { $i->icall(".$sec[$_].filter", qw/insert end/, $project->{sections}{filters}[$_]) for 0..3 } if $project->{sections}{filters};
	do { $i->icall(qw/.sections paneconfigure/, ".$sec[$_]", "-width", $project->{sections}{widths}[$_]) for 0..2 } if $project->{sections}{widths};
	$i->icall(qw/.sections configure -height /, $project->{sections}->{height}) if $project->{sections}->{height};
	
	$self->{area} = Ninja::MethodArea->new(main => $self)->construct;
	$self->{selectors} = Ninja::SelectorBoxes->new(main => $self)->construct;
	$self->{menu} = Ninja::Menu->new(main=>$self)->construct;

	$i->call(qw/wm protocol . WM_DELETE_WINDOW/, sub { $self->close });
	
	$i->Eval("tkwait window .");
	
	$self;
}

# закрывает основное окно
sub close {
	my ($self) = @_;
	
	my $i = $self->i;
	my $project = $self->project;
	my @sec = $self->jinnee->sections;
	
	%$project = $project->{find}? (find => $project->{find}): ();
		
	$project->{geometry} = $i->icall(qw/wm geometry ./);
	$project->{sections}{filters}[$_] = $i->Eval(".$sec[$_].filter get") for 0..3;
	$project->{sections}{widths}[$_] = $i->Eval("winfo width .$sec[$_]") for 0..2;
	$project->{sections}->{height} = $i->Eval("winfo height .sections");
	
	$project->{sel} = $self->selectors->get_essence;
	# for my $section ($self->jinnee->sections) {
		# $project->{selectors}{$section} = $self->selectors->$section->anchor;
		# last if $self->selectors->{section} eq $section;
	# }
	
	$project->{selectors}{areaCursor} = $self->area->pos if $self->area->enabled;
	
	$self->config->save;
	
	$i->Eval("destroy .");
	
	$self
}


sub pwd {
	use Cwd qw();
	Cwd::cwd()
}

sub errorbox {
	my ($self, $error, @args) = @_;
		
	$self->msgbox($error, -icon => "error", -title => "error", @args);
}

sub msgbox {
	my ($self, $message, @args) = @_;
	
	$self->i->call(qw/tk_messageBox/,
		-icon => "info", 
		-title => "message", 
		-type => "ok", 
		#-detail => "hi!", 
		-message => $message,
		@args
	);
	
	$self
}

1;