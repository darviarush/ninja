package Ninja::Menu;
# Меню

use common::sense;

sub new {
	my $cls = shift;
	bless {
		PATH => [],
		PATH_LABEL => [],
		@_,
	}, ref $cls || $cls;
}

sub main { shift()->{main} }
sub i { shift()->{main}{i} }

sub construct {
	my ($self) = @_;
	
	my $main = $self->main;
	my $i = $self->i;
	
	$i->Eval("
		menu .menu
		. configure -menu .menu"
	);
	
	push @{$self->{PATH}}, ".menu";
	
	my $config = $main->config;
	my $key;
	
	$self->cascade(file => 'Файл');
		$self->command('Открыть', "F5", sub { ::msg "hi!", \@_ });
		$self->separator;
		$self->command('Завершить', "F10", sub { $i->Eval("exit") });
	$self->pop;
	
	$self->cascade(project => 'Проект');
		$self->command('Создать', "F7", sub { $main->selectors->new_action });
		$self->command('Изменить', "F2", sub { $main->selectors->edit_action });
		$self->command('Удалить', "F8", sub { $main->selectors->delete_action });
		$self->separator;
		# $self->command('Отменить', "Control-Alt-Z", sub { $main->selectors->history_back_action });
		# $self->command('Применить', "Control-Alt-Y", sub { $main->selectors->history_next_action });
		# $self->separator;
		# $self->separator;
		# $self->command('Найти', "Control-F", sub { $main->selectors->find_action(0, 0) });
		# $self->command('Заменить', "Control-R", sub { $main->selectors->find_action(0, 1) });
		# $self->separator;
		# $self->command('Найти в проекте', "Control-Shift-F", sub { $main->selectors->find_action(1, 1) });
		# $self->command('Заменить в проекте', "Control-Shift-R", sub { $main->selectors->find_action(1, 1) });
	$self->pop;
	
	
	$self->cascade(editor => 'Редактор');
		# $self->command('Копировать', "Control-c, Control-Insert", "event generate . <<Copy>>");
		# $self->command('Вставить', "Control-v, Shift-Insert", "event generate . <<Paste>>");
		# $self->command('Вырезать', "Control-x", "event generate . <<Cut>>");
		$self->separator;
		# $self->command('Выделить всё', "Control-a", sub { $main->area->select_all });
		$self->separator;
		$self->command('Дублировать строку', "Control-d", sub { $main->area->dup_line_action });
		$self->separator;
		$self->command('Отменить ввод', "Control-Z", sub { $main->area->back_action });
		$self->command('Применить ввод', "Control-Y", sub { $main->area->next_action });
	$self->pop;
	
	$self->cascade(navigation => 'Навигация');
		$self->command('Назад', "Control-Alt-Left", sub { $main->selectors->move_back_action });
		$self->command('Вперёд', "Control-Alt-Right", sub { $main->selectors->move_next_action });
	$self->pop;
	
	$self
}

sub cascade {
	my ($self, $name, $label) = @_;
	
	my $menu = $self->top;
	my $submenu =  "$menu.$name";
	
	$self->i->Eval("
		menu $submenu -tearoff 0
		$menu add cascade -menu $submenu -label {$label} -underline 0
	");
	
	push @{$self->{PATH}}, $submenu;
	push @{$self->{PATH_LABEL}}, $label;
	$self
}

sub command {
	my ($self, $label, $key_default, $command) = @_;
	
	my $path = join "/", @{$self->{PATH_LABEL}};
	
	my $key = $self->main->config->at("menu/$path", $key_default);
	
	$self->i->call($self->top, qw/add command/, -label => $label, -accelerator => $key, -command => $command);
	
	my @keys = split /,\s*/, $key;
	my $first_key = shift @keys;
	$self->i->call(bind => "." => "<$first_key>" => $command);
	for my $second_key (@keys) {
		$self->i->Eval("bind . <$second_key> { event generate . <$first_key> }");
	}
	
	$self
}

sub separator {
	my ($self) = @_;
	
	$self->i->call($self->top, qw/add separator/);
	
	$self;
}

sub top { my $x=shift()->{PATH}; $x->[$#$x] }

sub pop {
	my ($self) = @_;
	pop @{$self->{PATH}};
	pop @{$self->{PATH_LABEL}};
	$self
}



1;