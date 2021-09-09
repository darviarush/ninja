package Jinnee;
# Компиллятор языка Джинни

use common::sense;

use parent 'Ninja::Role::Jinnee';

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

# список пакетов соответствующих фильтру
sub package_list {
	my ($self) = @_;
		
	map { my $inc=$_; 
		map { +{ path => $_, name => substr $_, 1+length $inc } } $self->ls($inc)
	} @{$self->{INC}}
}

# список классов в указанном пакете
sub class_list {
	my ($self, $package) = @_;
	
	map { my $path = $_;
		map { +{ path => $_, name => substr $_, 1+length $path } } $self->ls($path)
	} $package->{all}? (map { $self->ls($_) } @{$self->{INC}}): $package->{path}
}

# список категорий
sub category_list {
	my ($self, $class) = @_;
	
	my $path = $class->{path};
	
	map { +{ path => $_, name => substr $_, 1+length $path } } grep { !/\/\.\$\z/ } $self->ls($path)
}

# список методов. $category может быть '*'
sub method_list {
	my ($self, $category) = @_;
	
	map { my $path = $_;
		map { +{ path => $_, name => substr $_, 1+length($path), -2 } } $self->ls($path)
	} $category->{all}? (grep { !/\/\.\$\z/ } $self->ls($category->{path})): $category->{path}
}

#@category Читатели

# возвращает тело класса
sub class_get {
	my ($self, $class) = @_;
	return 1, $self->color( $self->file_load("$class->{path}/.\$", "Nil subclass $class->{name}\n\n") );
}

# Возвращает тело метода раскрашенное разными цветами
sub method_get {
	my ($self, $method) = @_;
	return 1, $self->color( $self->file_load("$method->{path}", "$method->{name}\n\n") );
}


#@category Писатели

# сохраняет и возвращает раскрашенным тело класса
sub class_put {
	my ($self, $class, $body) = @_;
	$self->file_save("$class->{path}/.\$", $body);
	
	if($body =~ /^\w+ subclass ([A-Z]\w+)/) {
		my $name = $1;
		my $path = $class->{path};
		$path =~ s!$class->{name}$!$name!;
		rename $class->{path}, $path and do {
			$class = {name => $name, path => $path};
		};
	}
	
	return $class, $self->color($body);
}

# Сохраняет тело метода
sub method_put {
	my ($self, $method, $body) = @_;
	$self->file_save("$method->{path}", $body);
	
	if($body =~ /^\S.*/) {
		my $name = $&;
		my $path = $method->{path};
		$path =~ s!$method->{name}(\.\$)$!$name$1!;
		rename $method->{path}, $path and do {
			$method = {name => $name, path => $path};
		};
	}

	return $method, $self->color($body);
}

#@category Демиурги

sub package_new {
	my ($self, $name) = @_;
	my $path = $self->{INC}[$#{$self->{INC}[0]}] . "/$name";
	$self->mkpath("$path/");
	die "Невозможно создать пакет $name ($path): $!" if !-e $path;
	return {name => $name, path => $path};
}

sub package_rename {
	my ($self, $name, $package) = @_;
	my $path = $package->{path};
	$path =~ s![^/]*$!$name!;
	rename $package->{path}, $path or die "Невозможно переименовать $package->{path} -> $path: $!";
	return {name => $name, path => $path};
}

sub class_new {
	my ($self, $name, $package) = @_;
	my $class = {name => $name, path => "$package->{path}/$name"};
	$self->class_get($class);
	$class
}

sub category_new {
	my ($self, $name, $class) = @_;
	my $path = "$class->{path}/$name";
	$self->mkpath("$path/");
	die "Невозможно создать категорию $name ($path): $!" if !-e $path;
	return {name => $name, path => $path};
}

sub category_rename {
	my ($self, $name, $category) = @_;
	my $path = $category->{path};
	$path =~ s![^/]*$!$name!;
	rename $category->{path}, $path or die "Невозможно переименовать $category->{path} -> $path: $!";
	return {name => $name, path => $path};
}

sub method_new {
	my ($self, $name, $category) = @_;
	my $class = {name => $name, path => "$category->{path}/$name.\$"};
	$self->method_get($class);
	$class
}


# Компилирует метод и вставляет его в файл с классом
sub method_compile {
	my ($self) = @_;
	$self
}

#@category Стиратели

sub package_erase {
	my ($self, $package) = @_;
	$self->rmtree($package->{path});
}

sub class_erase {
	my ($self, $class) = @_;
	$self->rmtree($class->{path});
}

sub category_erase {
	my ($self, $category) = @_;
	$self->rmtree($category->{path});
}

sub method_erase {
	my ($self, $method) = @_;
	$self->rmtree($method->{path});
}

#@category Синтаксис

sub tags {
	my ($self) = @_;
	
	+{
		number => [-foreground => '#8A2BE2'],
		string => [-foreground => '#008B8B'],
		code => [-foreground => '#ff1493'],
		
		variable => [-foreground => '#C71585'],
		attribute => [-foreground => '#C71585'],
		class => [-foreground => '#C71585'],
		method => [-foreground => '#4169E1'],
		unary => [-foreground => '#BC8F8F'],
		
		operator => [-foreground => '#8B0000'],
		prefix => [-foreground => '#008080'],
		postfix => [-foreground => '#1E90FF'],
		compare_operator => [-foreground => '#DC143C'],
		logic_operator => [-foreground => '#C71585'],
		
		staple => [-foreground => '#4682B4'],
		bracket => [-foreground => '#5F9EA0'],
		brace => [-foreground => '#00008B'],
		
		punct => [-foreground => '#00008B'],
		remark => [-foreground => '#696969', -relief => 'raised'],
		
		error => [-background => '#FF0000'],
	}
}

#-relief => 'raised',
# -font => [
	    # -family => 'courier', 
	    # -size => 12, 
	    # -weight => 'bold', 
	    # -slant => 'italic'
    # ],

sub lex {
	my ($self, $text) = @_;
	
	my $prev = 0;
	my $ret = [];

	my $indent4 = 0;

	while($text =~ m{
		(?<remark> ([\ \t]|^) \# [^\n]* ) |
		
		(?<number> [+-]?\d+(\.\d+)? ) |
		(?<string>

	-\| [\ \t]*\n ( {$ident4} [^\n]* $ | ^[\ \t]*$ )+

			|  """ (.*?) """ | ''' (.*?) ''' 
			| "(\\"|[^"])*" | '(\\'|[^'])*' 
		) |
		(?<code> `(\\`|[^`])*` ) |
		
		(?<class> \b [A-Z]\w+ \b) |
		(?<variable> \b [a-zA-Z] \b) |
		(?<attribute> \b _ [a-z]\w+ \b) |
		
		(?<logic_operator> \b (not|and|or) \b ) |
		(?<method> \b [a-z]\w+ \b) |
		
		(?<operator> ([-+*/^%\$?!<>=.:,;|&\\#])+ ) |
		
		(?<staple> [()] ) |
		(?<bracket> [\[\]] ) |
		(?<brace> [{}] ) |
		
		(?<punct> [|,;] ) |
		
		(?<newline> \n ) |
		(?<ident> ^ [\t\ ]+ ) |
		(?<space> [\t\ ]+ )
	}xmsng) {
		my $point = length $`;
		if($point - $prev != 0) {
			push @$ret, [substr($`, $prev, $point), "error"];
		}
		$prev = $point + length $&;
		
		my ($tag, $lexem) = each %+;
		$tag = "space", $ident = do { my $s=0; $s += $& eq "\t"? 4: 1 while $lexem =~ /./; $s } if $tag eq "ident";
		push @$ret, [$lexem, $tag];
	}
	
	if($prev != length $text) {
		push @$ret, [substr($text, $prev), "error"];
	}
	
	my $i = 0;
	for my $x ( @$ret ) {
		$i++;
		my $next = $ret->[$i];
		$next = $ret->[$i+1] if $next && $next->[1] eq "space";
		
		$x->[1] = "unary" if $x->[1] eq "method" && (
			!$next
			|| $next->[1] =~ /^(method|newline)\z/n
			|| $next->[0] =~ /^[\)\]\}]\z/n
		);
	}
	
	return $ret;
}

sub color {
	my ($self, $text) = @_;

	my $ret = $self->lex($text);
	
	for my $x ( @$ret ) {
		@$x = $x->[0] if $x->[1] =~ /^(newline|space)$/n;
	}
	
	$ret
}


#@category Компилляция

# компиллирует метод
sub compile {
	my ($self, $text) = @_;
	
	my $ret = $self->lex($text);
	
	# 1. убираем пробелы и строки перед методами и закрывающими скобками
	my $line = 1;
	my $char = 1;
	my @R = grep { $_->{type} ne "space" } map {
		
		my $lex = {
			line => $line,
			char => $char,
			lex => $_->[0],
			type => $_->[1],
		};

		$char += length $_->[0];

		$line++, $char = 1 if $_->[1] eq "newline";

		$lex
	} @$ret;
	
	for(my $i=0; $i<@R; $i++) {
		splice @R, $i+1, 1 if $R[$i]{lex} =~ /^[\{\[\(]\z/ && $i+1<@R && $R[$i+1]{type} eq "newline";
		splice @R, $i, 1 if $R[$i]{type} eq "newline" && $i+1<@R && $R[$i+1]{lex} =~ /^[\}\]\)]\z/;
	}
	
	# 2. строим дерево опираясь на скобки
	my @S = my $root = [];
	my @I = $root; # множество скобок
	for my $r (@R) {
		if($r->{lex} =~ /^[\{\[\(]\z/) { push @S, my $x=[]; push @I, $x }
		elsif($r->{lex} =~ /^[\}\]\)]\z/) { pop @S }
		else { push @{$S[$#S]}, $r }
	}
	
	# 3. внутри скобок производим ранжировку по операторам
	my $i = 0;
	my %op = map { $i++; map { ($_ => $i) } grep {$_} split /\s+/, $_ } grep {$_} split /\n/, "
		^
		* /
		+ -
		method
		< > =
		not
		and
		or
		!
		$
		~
		&
		|
	";
	
	@S = ();
	for my $s (@I) {
		my $prio = ref $s eq "ARRAY"? 0: $op{$s->{lex}};
		
		
	}
	
	$self
}


1;