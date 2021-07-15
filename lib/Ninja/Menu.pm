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
	
	$self->cascade('Правка');
	$self->command('Создать', "F7", sub { $main->selectors->new_action });
	$self->command('Изменить', "F2", sub { $main->selectors->edit_action });
	$self->command('Удалить', "F8", sub { $main->selectors->delete_action });
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
	
	$self->main->root->bind("<$key>" => $command);
	
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