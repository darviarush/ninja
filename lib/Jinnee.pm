package Jinnee;
# Компиллятор языка Джинни

use common::sense;

use parent 'Ninja::Role::Jinnee';


sub new {
	my $cls = shift;
	bless {
		INC => ["src"],
		classes => {},
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
		lunary => [-foreground => '#BC8F8F'],
		
		#operator => [-foreground => '#8B0000'],
		#prefix => [-foreground => '#008080'],
		#postfix => [-foreground => '#1E90FF'],
		#compare_operator => [-foreground => '#DC143C'],
		logic_operator => [-foreground => '#C71585'],
		
		staple => [-foreground => '#4682B4'],
		bracket => [-foreground => '#5F9EA0'],
		brace => [-foreground => '#00008B'],
		
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


	sub calc_indent { my ($lexem) = @_; my $s=0; $s += $& eq "\t"? 4: 1 while $lexem =~ /./g; $s }
	my $indent4;
	my $test_manyline = sub {
		my ($s) = @_;
		return if calc_indent($s) < $indent4;
		return 1;
	};

	while($text =~ m{
		(?<indent> ^ [\t\ ]* ) |
		(?<manyline>
			\|: [\ \t]* \n
			( ^ [\ \t]* (\n|\z) | (?<mli>[\t\ ]+) (??{ $test_manyline->($+{mli})? qr//: qr/(*FAIL)/ }) [^\n]* (\n|\z) )*
		) |

		(?<remark> ([\ \t]|^) \# [^\n]* ) |
		
		(?<number> [+-]?\d+(\.\d+)? ) |
		(?<string>
			""" (\\"|"(?!"")|[^"])* """(?!") | ''' (\\'|'(?!'')|[^'])* '''(?!')
			| "(\\"|[^"])*"(?!") | '(\\'|[^'])*'(?!')
		) |
		(?<code> `(\\`|[^`])*` | ``` (\\`|`(?!``)|[^`])* ```(?!`) ) |
		
		(?<class> \b [A-Z]\w+ \b) |
		(?<variable> \b [a-zA-Z] \b) |
		(?<attribute> \b _ [a-z]\w+ \b) |
		
		(?<logic_operator> \b (not|and|or) \b ) |
		(?<method> \b [a-z]\w+ \b) |
		
		(?<operator> ([-+*/^%\$?!<>=.:,;|&\\#])+ ) |
		
		(?<staple> [()] ) |
		(?<bracket> [\[\]] ) |
		(?<brace> [{}] ) |
		
		(?<newline> \n ) |
		(?<space> [\t\ ]+ )
	}xmsng) {
		my $point = length $`;
		if($point - $prev != 0) {
			push @$ret, [substr($`, $prev, $point), "error"];
		}
		$prev = $point + length $&;
		
		my ($tag, $lexem) = exists $+{manyline}? ("string", $+{manyline}): each %+;
		
		$tag = "space", $indent4 = calc_indent($lexem) + 2, do { next if $lexem eq "" } if $tag eq "indent";
		
		push @$ret, [$lexem, $tag];
	}
	
	if($prev != length $text) {
		push @$ret, [substr($text, $prev), "error"];
	}
	
	# ставим операторам и методам значение "унарный"
	# проверяем соответствие скобок
	# проверяем, чтобы операторы и методы стояли между соответствующими 
	my @S;
	my %rev_staple = qw/ } { ] [ ) ( /;
	my $i = 0;
	my $prev;
	for my $x ( @$ret ) {
		
		my $next = $ret->[$i+1];
		$next = $ret->[$i+2] if $next && $next->[1] eq "space";

		
		# скобки
		push @S, $x->[0] if $x->[0] =~ /^[\(\[\{]\z/n;
		if($x->[0] =~ /^[\)\]\}]\z/n) {
			if(@S && $S[$#S] eq $rev_staple{$x->[0]}) { pop @S }
			else { $x->[1] = "error" }
		}

		# проверка на выражение
		sub is_expression {
			my ($x, $t) = @_;
			for my $r (split //, $t) {
				return 1 if $x && (
					$r eq "a" && $x->[1] =~ /^(variable|class|attribute)\z/n
					|| $r eq "l" && $x->[1] eq "lunary"
					|| $r eq "u" && $x->[1] eq "unary"
					|| $r eq "m" && $x->[1] eq "method"
					|| $r eq "o" && $x->[1] eq "operator"
					|| $r eq "n" && $x->[1] eq "newline"
					|| $r eq "s" && $x->[1] eq "space"
					|| $r eq "(" && $x->[0] =~ /^[\(\[\{]\z/n
					|| $r eq ")" && $x->[0] =~ /^[\)\]\}]\z/n
				)
				|| $r =~ /^[\^\$]\z/n && !$x
				;
			}
			0
		}
		
		# операторы
		if($x->[1] eq "operator") {
			my $abs_prev = $i==0? undef: $ret->[$i-1];
			my $abs_next = $i==$#$ret? undef: $ret->[$i+1];

			if(is_expression($abs_prev, "au)") && is_expression($abs_next, "(a")) { $x->[1] = "method" }
			elsif(is_expression($abs_prev, "sn") && is_expression($prev, "au)") 
				&& is_expression($abs_next, "s") && is_expression($next, "(aom")) { $x->[1] = "method" }
			elsif(is_expression($abs_prev, "au)") && is_expression($abs_next, "sn)\$")) { $x->[1] = "unary" }
			elsif(is_expression($abs_prev, "^sn(") && is_expression($abs_next, "a(")) { $x->[1] = "lunary" }
			else { $x->[1] = "error" }
		}
		
		# методы: a method b
		# a unary method b
		elsif($x->[1] eq "method") {
			my $is_expression = is_expression($prev, "au(");

			if($is_expression && is_expression($next, "a)")) {}
			elsif($is_expression && is_expression($next, "mon)\$")) { $x->[1] = "unary" }
			else { $x->[1] = "error" }
		}
		
		$prev = $ret->[$i] if $ret->[$i][1] !~ /^(space|newline|remark)\z/;
		$i++;
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


#@category Компиляция

# разбирает код класса или метода и возвращает дерево разбора AST (грамматическинй ализатор)
sub to_tree {
	my ($self, $text) = @_;
	
	#my $text = $self->file_read($who->{path});
	
	my $ret = $self->lex($text);
	::msg $ret;
	
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

		die "$line:$char: syntax error `$_->[0]`" if $_->[1] eq "error";

		$char += length $_->[0];

		$line++, $char = 1 if $_->[1] eq "newline";

		$lex
	} @$ret;
	
	for(my $i=0; $i<@R; $i++) {
		splice @R, $i+1, 1 if $R[$i]{lex} =~ /^[\{\[\(]\z/ && $i+1<@R && $R[$i+1]{type} eq "newline";
		splice @R, $i, 1 if $R[$i]{type} eq "newline" && $i+1<@R && $R[$i+1]{lex} =~ /^[\}\]\)]\z/;
	}
	
	# 2. строим дерево опираясь на скобки
	my @K = my $root = [];
	my @I = \$root; # множество скобок
	for my $r (@R) {
		if($r->{lex} =~ /^[\{\[\(]\z/) { push @K, []; push @I, \$K[$#K] }
		elsif($r->{lex} =~ /^[\}\]\)]\z/) { pop @K }
		else { unshift @{$K[$#K]}, $r }
	}
	
	# 3. внутри скобок производим ранжировку по операторам
	my $i = 0;
	my %op = map { $i++; map { ($_ => $i) } grep {$_} split /\s+/, $_ } grep {$_} split /\n/, "
		unary
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
	
	# a + b * -c - x
	# (a + (b * (-c))) - x
	
	my @S; my @T;
	my $prio = sub { my ($s) = @_; ref $s ne "HASH"? 0: $op{$s->{type} eq "unary"? "unary": $s->{lex} =~ /^[[:punct:]]/? substr($s->{lex}, 0, 1): $s->{type}} };
	sub is_op { my ($s) = @_; ref $s eq "HASH" && $s->{type} =~ /^(unary|method)\z/n }
	sub is_unary { my ($s) = @_; ref $s eq "HASH" && $s->{type} eq "unary"  }
	my $shift_convolution = sub {	# сворачиваем все операторы в @S с меньшим приоритетом чем указанный и добавляем их в @T
		my ($prio1) = @_;
		while(@S && $prio->($S[$#S]) > $prio1) {
			my $xop = pop @S;
			if(is_unary($xop)) { push @T, [pop @T, $xop] } else { push @T, [pop(@T), pop(@T), $xop] }
		}
	};
	for my $II (@I) {		# скобки
		my $I = $$II;
		for my $r (@$I) {	# операнды и операторы в скобках
			if(ref $r eq "ARRAY") {	# если в скобках одно значение - то заменяем его
				die "В скобках осталось несколько операндов" if @$r != 1;
				$r = $r->[0];
				next;
			}
			elsif(!is_op($r)) { push(@T, $r) } 		# если это операнд, то помещаем его в T
			else {
				$shift_convolution->($prio->($r));
				push @S, $r;
			}
		}
		$shift_convolution->(0);
		
		::msg "x", @T;
		
		die "\@S не пуст!" if @S;
		die "\@T пуст!" if !@T;
		die "\@T=".@T.">1!" if @T>1;
		
		$$II = pop @T;
	}
	
	# # проставляем типы и объединяем многоарные методы, at put, например
	# $self->types($root, $who);
	# # уже с типами генерируем код на C
	# $self->morph($root, $who);
	
	$root
}

sub s_tree {
	my ($tree) = @_;
	ref $tree eq "ARRAY"? join("", "(", s_tree($tree),")"): $tree->{}
}


# Компилирует все пакеты в so, а классы наследуемые от Application - в бинарники
sub make {
	my ($self) = @_;
	
	for my $package ($self->package_list) {
		for my $class ($self->class_list($package)) {
			my $constructor = $class->{path};
			
			
			for my $category ($self->category_list($class)) {
				for my $method ($self->method_list($category)) {
					my $path_c = $method->{path};
					if(-M $method->{path}) {
						
					}
				}
			}
		}
	}
}



1;