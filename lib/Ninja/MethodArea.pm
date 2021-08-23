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
sub text { shift()->area->get('1.0', 'end-1c') }
#sub text { shift()->area->get('1.0', 'end-1c') }

sub construct {
	my ($self) = @_;

	$self->area->bind("<KeyRelease>" => sub { $self->update });
	#$self->area->bind("<Control-a>" => ;
	# $self->area->bind("<Control-c>" => sub { $self->area->eventGenerate("<<Copy>>") });
	# $self->area->bind("<Control-v>" => sub { $self->area->eventGenerate("<<Paste>>") });
	# $self->area->bind("<Control-x>" => sub { $self->area->eventGenerate("<<Cut>>") });

	# $self->area->bind("<Control-Insert>" => sub { $self->area->eventGenerate("<Control-c>") });
	# $self->area->bind("<Shift-Insert>" => sub { $self->area->eventGenerate("<Control-v>") });

	my $tags = $self->main->jinnee->tags;

	$self->area->tagConfigure($_ => @{$tags->{$_}}) for keys %$tags;

	$self
}

sub update {
	my ($self) = @_;
	
	my $text = $self->text;
	return $self if $text eq $self->{text};
	$self->{text} = $text;
	
	print "<<SAVE>>\n";
	
	my $pos = $self->area->index('insert');
	my ($lineno, $colno) = split /\./, $pos;
	$colno++;
	$self->main->position->configure(-text => "Line $lineno, Column $colno");
	
	# получаем колоризированный текст
	my $put = "$self->{type}_put";
	my ($who, $text) = eval { $self->main->jinnee->$put($self->{who}, $text) };
	$self->main->errorbox($@, -title => "Обновление окна"), return $self if $@;
	
	$self->set($text);
	
	if($who->{name} ne $self->{who}{name}) {
		my $sel = $self->{type} eq "class"? $self->main->selectors->classes: $self->main->selectors->methods;
		$sel->rename_element($sel->curselection->[0], $who);
	}
	
	$self->{who} = $who;
	
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

sub set {
	my ($self, $text) = @_;
	my $pos = $self->area->index('insert');
	$self->area->delete('1.0', 'end');
	
	my @text;
	for my $item (@$text) {
		$self->area->insert('end', @$item);
		#$self->area->see('end');
		push @text, $item->[0];
	}
	
	$self->area->SetCursor($pos);
	$self->area->focus;
	
	$self->{text} = join "", @text;
	
	$self
}


sub to_class {
	my ($self, $class) = @_;
	
	$self->{type} = "class";
	$self->{who} = $class;
	
	$self->enable;
	
	# текст с эскейп-последовательностями для раскраски
	my ($startlineno, $text) = eval { $self->main->jinnee->class_get($class); };
	$self->main->errorbox($@) if $@;
	$self->set($text);
}

sub to_method {
	my ($self, $method) = @_;
	my $path = $method->{path};
	
	$self->{type} = "method";
	$self->{who} = $method;
	
	$self->enable;
	
	# текст с эскейп-последовательностями для раскраски
	my ($startlineno, $text) = eval { $self->main->jinnee->method_get($method); };
	$self->main->errorbox($@) if $@;
	
	$self->set($text);
}

sub select_all { 
	my ($self) = @_;
	$self->area->SetCursor('end'); 
	$self->area->tagAdd('sel', '1.0', "end"); 
}

1;