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

sub to_method {
	my ($self, $method) = @_;
	my $path = $method->{path};
	
	# текст с эскейп-последовательностями для раскраски
	my ($startlineno, $text) = eval { $self->main->jinnee->method_get($method); };
	if($@) { 
		$self->area->MsgBox(
			-icon => "error", 
			-title => "error", 
			-type => "ok", 
			-detail => "hi!", 
			-message => $@,
		)->Show; 
		return $self;
	}
	
	$self->area->insert('end', $text);
	
	$self
}


1;