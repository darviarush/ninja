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
sub menu { shift()->{menu} }

sub construct {
	my ($self) = @_;
	
	my $main = $self->main;
	my $menu = $self->menu;
	
	push @{$self->{PATH}}, $menu;
	
	my $config = $main->config;
	my $key;
	
	$self->cascade('Файл');
		$self->command('Открыть', "F5", sub {});
		$self->top->separator;
		$self->command('Завершить', "F10", sub { $main->root->quit });
	$self->pop;
	
	$self->cascade('Проект');
		$self->command('Создать', "F7", sub { $main->selectors->new_action });
		$self->command('Изменить', "F2", sub { $main->selectors->edit_action });
		$self->command('Удалить', "F8", sub { $main->selectors->delete_action });
		$self->top->separator;
		$self->command('Отменить', "Control-Alt-Z", sub { $main->selectors->history_back_action });
		$self->command('Применить', "Control-Alt-Y", sub { $main->selectors->history_next_action });
		$self->top->separator;
		$self->command('Отменить ввод', "Control-Z", sub { $main->selectors->area_back_action });
		$self->command('Применить ввод', "Control-Y", sub { $main->selectors->area_next_action });
		$self->top->separator;
		$self->command('Найти', "Control-F", sub { $main->selectors->find_action(0, 0) });
		$self->command('Заменить', "Control-R", sub { $main->selectors->find_action(0, 1) });
		$self->top->separator;
		$self->command('Найти в проекте', "Control-Shift-F", sub { $main->selectors->find_action(1, 1) });
		$self->command('Заменить в проекте', "Control-Shift-R", sub { $main->selectors->find_action(1, 1) });
	$self->pop;
	
	
	$self->cascade('Редактор');
		$self->command('Копировать', "Control-c, Control-Insert", sub { $main->area->area->eventGenerate("<<Copy>>") });
		$self->command('Вставить', "Control-v, Shift-Insert", sub { $main->area->area->eventGenerate("<<Paste>>") });
		$self->command('Вырезать', "Control-x", sub { $main->area->area->eventGenerate("<<Cut>>") });
		$self->top->separator;
		$self->command('Выделить всё', "Control-a", sub { $main->area->select_all });
	$self->pop;
	
	$self->cascade('Навигация');
		$self->command('Назад', "Control-Alt-Left", sub { $main->selectors->move_back_action });
		$self->command('Вперёд', "Control-Alt-Right", sub { $main->selectors->move_next_action });
	$self->pop;
	
	$self
}

sub cascade {
	my ($self, $label) = @_;
	my $submenu = $self->top->Menu();
	$self->top->cascade(-label => $label, -menu => $submenu);
	push @{$self->{PATH}}, $submenu;
	push @{$self->{PATH_LABEL}}, $label;
	$self
}

sub command {
	my ($self, $label, $key_default, $command) = @_;
	
	my $path = join "/", @{$self->{PATH_LABEL}};
	
	my $key = $self->main->config->at("menu/$path", $key_default);
	$self->top->command(-label => $label, -accelerator => $key, -command => $command);
	
	my @keys = split /,\s*/, $key;
	my $first_key = shift @keys;
	$self->main->root->bind("<$first_key>" => $command);
	my $action = sub { $self->main->root->eventGenerate("<$first_key>") };
	for my $second_key (@keys) {
		$self->main->root->bind("<$second_key>" => $action);
	}
	
	$self
}


sub top { my $x=shift()->{PATH}; $x->[$#$x] }

sub pop {
	my ($self) = @_;
	pop @{$self->{PATH}};
	pop @{$self->{PATH_LABEL}};
	$self
}



1;