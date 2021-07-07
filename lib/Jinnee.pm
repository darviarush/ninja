package Jinnee;
# Компиллятор языка Джинни

use common::sense;


sub new {
	my $cls = shift;
	bless {
		INC => ["kernel", "src"],
		@_
	}, $cls;
}

#@category Компиллятор

# Компилирует метод и вставляет его в файл с классом
sub method_compile {
	my ($self) = @_;
	$self
}


#@category Пакеты

# список пакетов соответствующих фильтру
sub package_list {
	my ($self, $re) = @_;
	grep { /$re/i } map { glob "$_/*" } @{$self->{INC}}
}

# список классов в указанных пакетах
sub class_list {
	my ($self, $re, $packages) = @_;
	$self
}

# список категорий
sub categiry_list {
	my ($self, $re, $classes) = @_;
	$self
}

# список методов
sub categiry_list {
	my ($self, $re, $classes) = @_;
	$self
}

1;