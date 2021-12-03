package Ninja::Monitor::Sector;
# Драйвер секционального редактора Ninja для наблюдения за участками файловой системы

use common::sense;

use parent "Ninja::Role::Monitor";

use Ninja::Ext::File qw/f/;


sub new {
	my $cls = shift;
	bless {
		INC => ["."],		# @INC
		EXC => ["./.git"],	# сюда не заходим
		@_,
	}, ref $cls || $cls;
}

#@category Списки

# список пакетов
# классы в корне inc либо забрасываются в одноимённые пакеты, либо попадают в пакет [-]
sub package_list {
	my ($self) = @_;
	
	#$root? {root=>1, section=>"packages", name=>"[§]"}
	my %x;
	for my $inc (@{$self->{INC}}) {
		my ($D, $F) = f($inc)->lstree($self->{EXC});
		$x{substr $_->dir, length($inc)+1}++ for @$F;
	}
	
	map {
		+{
			section => "packages",
			name => $_ eq ""? "[§]": $_,
			path => $_,
		}
	} sort keys %x;
}

# список классов в указанном пакете
sub class_list {
	my ($self, $package) = @_;
	
	my $subpath = (length($package->{path})? "/": "") . $package->{path};
	
	map {
		my $inc = $_;
		my $len = length($inc)+1;
		map {+{
			section => "classes",
			package => $package,
			path => $_->{path},
			inc => $inc,
			name => $_->name,
		}} grep { -f $_->{path} } f($inc . $subpath)->ls;
	} @{$self->{INC}};
}

# список категорий
sub category_list {
	my ($self, $class) = @_;
	
	my $file = f $class->{path};
	
	my @A = $self->jinnee($file)->parse($file->read);
	
	map { $_->{class} = $class; $_ } grep { $_->{section} eq "categories" } @A;
}

# список методов
sub method_list {
	my ($self, $category) = @_;

	my $class = $category->{class};
	my $file = f $class->{path};
	map { $_->{category} = $category; $_ }
		grep { $_->{section} eq "methods" && $_->{category}->{name} eq $category->{name} } 
				$self->jinnee($file)->parse($file->read);
}


#@category Читатели

# возвращает текст файла и конец заголовка класса
sub _class_get {
	my ($self, $class) = @_;
	my $file = f $class->{path};
	my $code = $file->read;
	my @A = $self->jinnee($file)->parse($code);
	
	# ищем первую категорию, чтобы до неё вывести класс
	my $first;
	for(@A) { $first = $_, last if $_->{section} eq "categories" }
	
	return $code, $first? $first->{from}: length($code), \@A;
}

# возвращает номер строки и заголовок класса
sub class_get {
	my ($self, $class) = @_;	
	my ($code, $end) = $self->_class_get($class);
	return 1, substr $code, 0, $end;
}

# строка
sub _line {
	my ($code, $from) = @_;
	
	my $line = 1;
	while($code =~ /\n/g) {
		last if length($`) > $from;
		$line++;
	}
	
	$line
}

# возвращает код файла и позицию начала и конца метода
sub _method_get {
	my ($self, $method) = @_;
	my $file = f $method->{category}{class}{path};
	my $code = $file->read;
	my @A = $self->jinnee($file)->parse($code);

	my $first;
	for(@A) { $first = $_, last if $_->{name} eq $method->{name} && $_->{section} eq "methods" }
	
	return $code, $first->{from} // 0, $first->{end} // length($code);
}

# Возвращает номер строки и тело метода
sub method_get {
	my ($self, $method) = @_;
	
	my ($code, $from, $end) = $self->_method_get($method);
	
	return _line($code, $from), substr($code, $from, $end - $from);
}

#@category Писатели

# сохраняет и если нужно - переименовывает. Возвращает переименованный объект
sub class_put {
	my ($self, $class, $text) = @_;
	
	my ($code, $end, $A) = $self->_class_get($class);

	# замена текста заголовка
	$code =~ s/^(.{$end})/$text/s;
	
	f($class->{path})->write($code);

	#$self->jinnee($class)->;

	# переименование файла класса по пакету
	if($text =~ /^package\s+([\w:]+)/) {
		my $path = $1;
		my ($new_name) = $path =~ /(\w+)$/;
		my ($name) = $class->{path} =~ /(?:^|\/)(\w+)\.[^.]+$/;
		if($name ne "" and $new_name ne "" and $name ne $new_name) {
			$path = $class->{path};
			$path =~ s/$name(\.[^.]+)$/$new_name$1/;
			undef $!;
			rename $class->{path}, $path and do {
				$class = {%$class, name => $new_name, path => $path};
			};
		}
	}
	
	return $class;
}



1;