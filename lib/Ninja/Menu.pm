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
	
	$self->cascade('Файл');
		$self->command('Открыть', "F5", sub { ::msg "hi!", \@_ });
		$self->separator;
		$self->command('Завершить', "F10", sub { $i->Eval("exit") });
	$self->pop;
	
	$self->cascade('Проект');
		$self->command('Создать', "F7", sub { $main->selectors->new_action });
		$self->command('Изменить', "F2", sub { $main->selectors->edit_action });
		#$self->command('Копировать', "F5", sub { $main->selectors->copy_action });
		$self->command('Удалить в корзину', "F8", sub { $main->selectors->delete_action });
		$self->command('Восстановить из корзины', "Shift-F8", sub { $main->selectors->restore_action });
		# $self->separator;
		# $self->command('Отменить', "Control-Alt-Z", sub { $main->selectors->history_back_action });
		# $self->command('Применить', "Control-Alt-Y", sub { $main->selectors->history_next_action });
		# $self->separator;
		$self->separator;
		$self->command('Найти в проекте', "Control-Shift-F, Control-Shift-N", sub { $main->selectors->find_action(0, 0) }, ". .t.text");
		$self->command('Заменить в проекте', "Control-Shift-R", sub { $main->selectors->find_action(0, 1) }, ". .t.text");
	$self->pop;
	
	
	$self->cascade('Редактор');
		# $self->command('Копировать', "Control-c, Control-Insert", "event generate . <<Copy>>");
		# $self->command('Вставить', "Control-v, Shift-Insert", "event generate . <<Paste>>");
		# $self->command('Вырезать', "Control-x", "event generate . <<Cut>>");
		#$self->separator;
		# $self->command('Выделить всё', "Control-a", sub { $main->area->select_all });
		#$self->separator;
		$self->command('Дублировать строку', "Control-d", '.t.text insert {insert lineend} "\\n[.t.text get {insert linestart} {insert lineend}]"', '.t.text');
		$self->command('Удалить строку', "Control-Delete", '.t.text delete {insert linestart} {insert lineend+1c}', '.t.text');
		$self->separator;
		$self->command('Найти', "Control-f", sub { $main->selectors->find_action(1, 0) }, '.t.text');
		$self->command('Заменить', "Control-r", sub { $main->selectors->find_action(1, 1) }, '.t.text');
	$self->pop;
	
	# $self->cascade(navigation => 'Навигация');
		# $self->command('Назад', "Control-Alt-Left", sub { $main->selectors->move_back_action });
		# $self->command('Вперёд', "Control-Alt-Right", sub { $main->selectors->move_next_action });
	# $self->pop;
	
	$self->cascade('Настройки');
		$self->command('Сбросить комбинации клавишь', "Control-Alt-Key-1", sub {
			delete $config->{menu};
			$self->i->Eval("destroy .menu");
			$self->construct;
		});
	$self->pop;
	
	$self
}

sub cascade {
	my ($self, $label) = @_;
	
	my $menu = $self->top;
	my $submenu =  "$menu." . _translate($label);
	
	$self->i->Eval("
		menu $submenu -tearoff 0
		$menu add cascade -menu $submenu -label {$label} -underline 0
	");
	
	push @{$self->{PATH}}, $submenu;
	push @{$self->{PATH_LABEL}}, $label;
	$self
}

sub command {
	my ($self, $label, $key_default, $command, $widgets) = @_;
	
	my $key = $self->main->config->at(["menu", @{$self->{PATH_LABEL}}, $label], $key_default);
	
	$self->i->call($self->top, qw/add command/, -label => $label, -accelerator => $key, -command => $command);
	
	if(ref $command) {
		$self->i->CreateCommand(my $x = "::perl::menu_" . _translate($label), $command);
		$command = $x;
	}
		
	my @keys = split /,\s*/, $key;
	my $first_key = shift @keys;
	
	eval {
	
		for my $widget (split /\s+/, $widgets // ".") {
			$self->i->Eval("bind $widget <$first_key> { $command; break }");
			for my $second_key (@keys) {
				$self->i->Eval("bind $widget <$second_key> { event generate $widget <$first_key>; break }");
			}
		}
		
	};
	
	::msg $@ if $@;
	
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


# транслитерирует
sub _translate {
	my ($s) = @_;
	$s = lc $s;
	
	my %S = qw/
	а a б b в v г g д d е e ё oh ж jh з z и i й j к k л l м m н n о o п p р r с s т t 
	у u ф f х hh ц c ч ch ш sh щ csh ъ qh ы y ь q э eh ю uh я ah
	/;
	$s =~ s{ [абвгдежзийклмнопрстуфхцчшщъыьэюяё] }{	$S{$&} }gixe;
	
	$s =~ s/\W/_/g;
	$s
}


1;