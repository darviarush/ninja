package Ninja::MethodArea;
# 
use common::sense;

sub new {
	my $cls = shift;
	bless {		
		@_,
	}, ref $cls || $cls;
}

sub main { shift->{main} }
sub i { shift->{main}{i} }

sub text { shift->i->Eval(".t.text get 1.0 end-1c") }


sub construct {
	my ($self) = @_;

	# TODO: подсвечивать слово под курсором
	$self->i->call(qw/bind .t.text <KeyRelease>/, sub { $self->update });
	
	my $tags = $self->main->jinnee->tags;

	$self->i->invoke(qw/.t.text tag configure/, $_ => @{$tags->{$_}}) for sort keys %$tags;
	
	# устанавливаем размер табуляции
	#::msg("x", $self->area->configure("-font")->[4]->measure);
	#$self->area->configure(-tabs => 4);

	$self
}


# обновление 
sub update {
	my ($self) = @_;

	return $self if $self->i->Eval(".t.text cget -state") eq 'disabled';

	my $text = $self->text;
	return $self if $text eq $self->{text};

	#print "<<SAVE>>$text\n";

	# записываем текст
	my $put = "$self->{type}_put";
	my $who = eval { $self->main->jinnee->$put($self->{who}, $text) };
	$self->main->errorbox($@, -title => "Обновление окна"), return $self if $@;

	$self->set($text);

	if($who->{name} ne $self->{who}{name}) {
		my $sel = $self->{type} eq "class"? $self->main->selectors->classes: $self->main->selectors->methods;
		$sel->rename_element($sel->anchor, $who);
		my $x = "$self->{type}_select";
		$self->main->selectors->$x;
	}

	$self->{who} = $who;

	$self
}

sub disable {
	my ($self) = @_;
	$self->i->Eval("
		.t.text delete 1.0 end
		.t.text configure -state disabled
		.f.position configure -text {}
	");
	$self
}

sub enable {
	my ($self) = @_;
	$self->i->Eval("
		.t.text configure -state normal
	");
	$self
}

sub enabled { my ($self) = @_; $self->i->Eval(".t.text cget -state") eq "normal" }
sub disabled { my ($self) = @_; $self->i->Eval(".t.text cget -state") eq "disabled" }

sub set {
	my ($self, $text) = @_;
	
	my $lex = $self->main->jinnee->color($self->{who}, $text);
	
	my $pos = $self->i->Eval(".t.text index insert");
	$self->i->Eval(".t.text delete 1.0 end");
	
	$self->i->invoke(qw/.t.text insert end/, @$_) for @$lex;
	$self->goto($pos);
	
	$self->{text} = $text;
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
	$self->goto("1.end");
	
	$self->i->Eval("after 10 {focus .t.text}");
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
	$self->goto("1.end");
	
	
	$self->i->Eval("after 10 {focus .t.text}");
	
	$self
}

# переставляет курсор
sub goto {
	my ($self, $pos) = @_;
	
	$self->i->Eval("
		tk::TextSetCursor .t.text $pos
		.t.text see $pos
		focus .t.text
	");
	$self
}

# позиция курсора или указанная
sub pos {
	my ($self, $pos) = @_;
	$pos //= "insert";
	my $pos = $self->i->invoke(qw/.t.text index/, $pos);
	wantarray? split(/\./, $pos): $pos;
}

# количество строк в тексте. Совпадает с последней строкой
sub lines {
	my ($self) = @_;
	my ($lines) = $self->pos('end');
	$lines
}

# выбирает текст
sub select {
	my ($self, $from, $to) = @_;
	$self->i->Eval("
		focus .t.text
		.t.text tag add sel $from $to
	");
	$self
}

# передвигает выделенные строки или строку под курсором вверх
sub line_up_action {
	my ($self) = @_;
	
	# TODO: перемещение для выделенного блока
	#my () = eval { $self->pos("sel.first") };
	
	my ($line, $char) = $self->pos;
	
	return if $line == 1;
	
	my $this_line = $self->i->Eval(".t.text get {insert linestart} {insert lineend}");
	$self->i->Eval(".t.text delete {insert linestart} {insert lineend+1c}");
	
	$line--;
	$self->i->invoke(qw/.t.text insert/, "$line.0", "$this_line\n");
	
	$self->goto("$line.$char");
	
	$self->update;
}

# # передвигает выделенные строки или строку под курсором вниз
sub line_down_action {
	my ($self) = @_;
	
	my ($line, $char) = $self->pos;
	return if $line == $self->lines;
	
	my $this_line = $self->i->Eval(".t.text get {insert linestart} {insert lineend}");
	$self->i->Eval(".t.text delete {insert linestart} {insert lineend+1c}");
	
	$self->i->invoke(qw/.t.text insert/, "$line.end", "\n$this_line");
	$line++;
	
	$self->goto("$line.$char");
	
	$self->update;
}

# дублирует строку
sub line_dup_action {
	my ($self) = @_;
	$self->i->Eval('
		.t.text insert {insert lineend} "\\n[.t.text get {insert linestart} {insert lineend}]"
	');
	$self->update;
}

# удаляет строку
sub line_del_action {
	my ($self) = @_;
	$self->i->Eval('
		.t.text delete {insert linestart} {insert lineend+1c}
	');
	$self->update;
}

1;