package Jinnee;
# Компиллятор языка Джинни

use common::sense;


sub new {
	my $cls = shift;
	bless {
		INC => ["kernel", "src"],
		packages => {},			# пакет => { INC => "src" }
		classes => {},			# класс => { package => }
		@_
	}, $cls;
}


#@category Класс

# подгружает или создаёт файл
sub _load {
	my ($path, $template) = @_;
	my $f;
	open $f, $path and do { read $f, my $buf, -s $f;	close $f; $buf }
	or do {
		mkdir $`, 0644 while $path =~ /\//g;
		open $f, ">", $path or die "Не могу создать $path. Причина: $!";
		print $f, $template;
		close $f;
		$template
	}
}


# возвращает тело класса
sub class_get {
	my ($self, $class) = @_;	
	return 1, _load("$class->{path}/.\$", "Nil subclass $class->{name}\n\n");
}


#@category Метод

# Возвращает тело метода раскрашенное разными цветами
sub method_get {
	my ($self, $method) = @_;
	return 1, _load("$method->{path}", "$method->{name}\n\n");
}

# Компилирует метод и вставляет его в файл с классом
sub method_compile {
	my ($self) = @_;
	$self
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



1;