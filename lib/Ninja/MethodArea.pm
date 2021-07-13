package Ninja::MethodArea;
# 
use common::sense;

sub new {
	my $cls = shift;
	bless {		
		@_,
	}, ref $cls || $cls;
}

sub area { shift()->{area} } 
sub main { shift()->{main} }
sub text { shift()->area->get('1.0', 'end') }
#sub text { shift()->area->get('1.0', 'end-1c') }

sub construct {
	my ($self) = @_;
	
	$self->area->bind("<KeyRelease>" => sub { $self->update });
	
	$self
}

sub update {
	my ($self) = @_;
	
	my $pos = $self->area->index('insert');
	my ($lineno, $colno) = split /\./, $pos;
	$colno++;
	$self->main->position->configure(-text => "Line $lineno, Column $colno");
	
	$self
}

sub disable {
	my ($self) = @_;
	$self->area->delete('1.0', 'end');
	$self->area->configure(-state => 'disabled');
	$self
}

sub enable {
	my ($self) = @_;
	$self->area->configure(-state => 'normal');
	$self
}


sub to_class {
	my ($self, $class) = @_;
	
	$self->enable;
	
	# текст с эскейп-последовательностями для раскраски
	my ($startlineno, $text) = eval { $self->main->jinnee->class_get($class); };
	$self->errorbox($@) if $@;
	
	$self->area->delete('1.0', 'end');
	$self->area->insert('end', $text);
}

sub to_method {
	my ($self, $method) = @_;
	my $path = $method->{path};
	
	$self->enable;
	
	# текст с эскейп-последовательностями для раскраски
	my ($startlineno, $text) = eval { $self->main->jinnee->method_get($method); };
	$self->errorbox($@) if $@;
	
	$self->area->delete('1.0', 'end');
	$self->area->insert('end', $text);
	
	$self
}

sub errorbox {
	my ($self, $error) = @_;
	
	$self->area->MsgBox(
		-icon => "error", 
		-title => "error", 
		-type => "ok", 
		-detail => "hi!", 
		-message => $error,
	)->Show; 
	
	$self
}


1;