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
	map { $_->{class} = $class; $_ } grep { $_->{section} eq "categories" } $self->jinnee($file)->parse($file->read);
		
	# local $_ = $self->file_read($path);
	
	# my @cat;
	# while(/^#\@category[ \t]+(.*?)[ \t]*$/gm) {
		# push @cat, {section=>"categories", class=>$class, path=>$path, name=>$1};
	# }
	# # ∰ - три факториала в круге
	# # Qiyeshipin Shengchanxuke logo.svg
	# return {section=>"categories", class=>$class, path=>$path, name=>"§", header=>1}, @cat
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

sub _line {
	my ($code, $from) = @_;
	
	my $line = 1;
	while($code =~ /\n/g) {
		last if length($`) > $from;
		$line++;
	}
	
	$line
}

# возвращает номер строки и тело класса
sub class_get {
	my ($self, $class) = @_;
	
	my $file = f $class->{path};
	my $code = $file->read;
	
	# ищем первую категорию или метод, чтобы до неё вывести класс
	my $first;
	for my $who ($self->jinnee($file)->parse($code)) {
		$first = $who, last if $who->{section} =~ /^(categories|methods)$/;
	}
	
	# если категория или метод не найдены, то возвращаем весь файл
	return 1, $code if !$first;
	
	# если это метод, то он имеет право на комментарии перед ним
	
	# если это категория, то 
	return 1, substr $code, 0, $first->{mid};
}

# Возвращает номер строки и тело метода
sub method_get {
	my ($self, $method) = @_;
	
	my $file = f $method->{category}{class}{path};
	my $code = $file->read;
	my ($mmethod) = grep { $_->{section} eq "methods" && $_->{name} eq $method->{name} } $self->jinnee($file)->parse($code);
	
	return _line($code, $mmethod->{from}), substr $code, $mmethod->{from}, $mmethod->{to};
}

#@category Писатели

# сохраняет и если нужно - переименовывает. Возвращает переименованный объект
sub class_put {
	my ($self, $class, $text) = @_;
	
	my $file = f $class->{path};
	
	
	# замена текста заголовка
	my $file = $self->file_read($class->{path});
	$file =~ s!^(.*?)(\nsub\b|\n#\@category\b|$)!$text$2!s;
	$self->file_save($class->{path}, $file);
	
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