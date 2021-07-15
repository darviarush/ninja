package Jinnee;
# Компиллятор языка Джинни

use common::sense;


sub new {
	my $cls = shift;
	bless {
		INC => ["kernel", "src"],
		packages => {},			# пакет => { INC => "src" }
		@_
	}, $cls;
}


#@category Списки

#!!
#A package_list r
#^A inc -> x |map "$x/*" glob ++ "$x/*" glob -> n |if n !~ /\/\.{1,2}\z/ |map n slice 1 + x% |if n ~ /$r/i

sub ls($) {
	my ($path) = @_;
	return (grep { !/\/(\.{1,2}|\.\$)\z/ } <"$path/.*">), <"$path/*">;
}


# список пакетов соответствующих фильтру
sub package_list {
	my ($self, $re) = @_;
	return +{name => "*", all => 1},
	grep { /$re/i } map { my $x=$_; map {
		+{ path => $_, name => substr $_, 1+length $x }
	} ls $_ } @{$self->{INC}}
}

# список классов в указанном пакете
sub class_list {
	my ($self, $re, $package) = @_;
	
	grep { /$re/i }	
	map { my $path = $_;
		map {
			+{ path => $_, name => substr $_, 1+length $path }
		} ls $path
	} $package->{all}? (map { ls $_ } @{$self->{INC}}): $package->{path}

}

# список категорий
sub category_list {
	my ($self, $re, $class) = @_;
	
	my $path = $class->{path};
	
	return +{name => "*", path => $class->{path}, all => 1},
	grep { /$re/i }	map {
		+{ path => $_, name => substr $_, 1+length $path }
	} ls $path
}

# список методов. $category может быть '*'
sub method_list {
	my ($self, $re, $category) = @_;
	
	my $path = $category->{path};
	
	grep { /$re/i }	
	map { my $path = $_;
		map { 
			+{ path => $_, name => substr $_, 1+length($path), -2 }
		} (grep { !/\/\.{1,2}\z/ } <"$path/.*">), <"$path/*">
	} $category->{all}? ls $category->{path}: $category->{path}
}




#@category Файлы

sub _mkpath {
	my ($path) = @_;
	mkdir $`, 0644 while $path =~ /\//g;
}

# подгружает или создаёт файл
sub _load {
	my ($path, $template) = @_;
	my $f;
	open $f, $path and do { read $f, my $buf, -s $f;	close $f; $buf }
	or do {
		_mkpath($path);
		open $f, ">", $path or die "Не могу создать $path. Причина: $!";
		print $f, $template;
		close $f;
		$template
	}
}

sub _ls {
	my ($path) = @_;
	return (grep { !/\/\.{1,2}\z/ } <"$path/.*">), <"$path/*">;
}

sub _rmtree {
	my ($path) = @_;
	
	unlink($path) || die("Нельзя удалить файл $path: $!"), return if !-d $path;
	
	_rmtree($_) for _ls($path);
	rmdir $path;
}


#@category Читатели

# возвращает тело класса
sub class_get {
	my ($self, $class) = @_;	
	return 1, _load("$class->{path}/.\$", "Nil subclass $class->{name}\n\n");
}


# Возвращает тело метода раскрашенное разными цветами
sub method_get {
	my ($self, $method) = @_;
	return 1, _load("$method->{path}", "$method->{name}\n\n");
}



#@category Демиурги

sub package_new {
	my ($self, $name) = @_;
	my $path = $self->{INC}[$#{$self->{INC}[0]}] . "/$name";
	_mkpath("$path/");
	die "Невозможно создать пакет $name ($path): $!" if !-e $path;
	return {name => $name, path => $path};
}

sub package_rename {
	my ($self, $package, $name) = @_;
	my $path = $package->{path};
	$path =~ s![^/]*$!$name!;
	rename $package->{path}, $path or die "Невозможно переименовать $package->{path} -> $path: $!";
	return {name => $name, path => $path};
}

# Компилирует метод и вставляет его в файл с классом
sub method_compile {
	my ($self) = @_;
	$self
}



#@category Стиратели

sub package_erase {
	my ($self, $package) = @_;
	_rmtree($package->{path});
}


1;