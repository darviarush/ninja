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

sub _save {
	my ($path, $body) = @_;
	my $f;
	open $f, ">", $path or die "Не могу создать $path. Причина: $!";
	print $f $body;
	close $f;
}

# подгружает или создаёт файл
sub _load {
	my ($path, $template) = @_;
	my $f;
	
	open $f, "<", $path and do { read $f, my $buf, -s $f;	close $f; ::p my $x="_load $path"; $buf }
	or do { # если $buf выше будет пустой, то выполнится и эта ветвь
		_mkpath($path);
		open $f, ">", $path or die "Не могу создать $path. Причина: $!";
		print $f $template;
		close $f;
		::p my $x="_create $path";
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
	return 1, $self->color( _load("$class->{path}/.\$", "Nil subclass $class->{name}\n\n") );
}

# Возвращает тело метода раскрашенное разными цветами
sub method_get {
	my ($self, $method) = @_;
	return 1, $self->color( _load("$method->{path}", "$method->{name}\n\n") );
}


#@category Писатели

# возвращает тело класса
sub class_put {
	my ($self, $class, $body) = @_;
	_save("$class->{path}/.\$", $body);
	$self->color($body);
}

# Сохраняет тело метода
sub method_put {
	my ($self, $method, $body) = @_;
	_save("$method->{path}", $body);
	$self->color($body);
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

#@category Синтаксис

sub tags {
	my ($self) = @_;
	
	+{
		number => [-foreground => '#8A2BE2'],
		string => [-foreground => '#1E90FF'],
		
		variable => [-foreground => '#008080'],
		class => [-foreground => '#C71585'],
		
		operator => [-foreground => '#8B0000'],
		compare_operator => [-foreground => '#DC143C'],
		logic_operator => [-foreground => '#C71585'],
		
		staple => [-foreground => '#4682B4'],
		bracket => [-foreground => '#5F9EA0'],
		brace => [-foreground => '#00008B'],
		
		punct => [-foreground => '#00008B'],
		remark => [-foreground => '#00008B'],
	}
}

sub color {
	my ($self, $text) = @_;

	my $prev = 0;
	my $ret = [];

	my $re_op = '[-+*/^%$!<>=.:,;|&]';

	my $re = qr{
		(?<number> [+-]?\d+(\.\d+)? ) |
		(?<string> "(\\"|.)*") |
		
		(?<class> \b [A-Z]\w+ \b) |
		(?<variable> \b [a-zA-Z] \b) |
		
		(?<logic_operator> \b (not|and|or) \b ) |
		(?<compare_operator> [<>=]$re_op* ) |
		(?<operator> $re_op+ ) |
		
		(?<staple> [()] ) |
		(?<bracket> [\[\]] ) |
		(?<brace> [{}] ) |
		
		(?<punct> [|,;] ) |
		
		(?<newline> \n ) |
		(?<space> \s+ )
	}xsn;
	while($text =~ /$re/go) {
		my $point = length $`;
		if($point - $prev != 0) {
			push @$ret, [substr $`, $prev, $point];
		}
		$prev = $point + length $&;
		
		my ($tag, $lexem) = each %+;
		push @$ret, [$lexem, $tag !~ /^(newline|space)$/n? $tag: ()];
	}
	
	$ret
}

1;