package Jinnee;
# Компиллятор языка Джинни

use common::sense;

use parent 'Ninja::Role::Jinnee';


our $DEBUG = 0;


sub new {
	my $cls = shift;
	bless {
		INC => ["src"],
		# class->{$name}->{prop}{$name} => type (class name)
		#      ->{method}{"at put"} => {args=>[type, type]}
		#      ->{mtime} => unixtime
		class => {},
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
		
		(?<integer> \d+ ) |
		(?<number> \d+\.\d+ ) |
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
					$r eq "a" && $x->[1] =~ /^(variable|class|attribute|integer|number|string)\z/n
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
			my $abs_next = $ret->[$i+1];

			# ::msg "op", {
					# "op" => $x->[0],
					# "abs_prev" => $abs_prev,
					# "abs_next" => $abs_next,
					# "prev" => $prev,
					# "next" => $next,
				# };

			if(is_expression($abs_prev, "au)") && is_expression($abs_next, "(a")) { $x->[1] = "method" }
			elsif(is_expression($abs_prev, "sn") && is_expression($prev, "au)") 
				&& is_expression($abs_next, "s") && is_expression($next, "(aom")) { $x->[1] = "method" }
			elsif(is_expression($abs_prev, "au)") && is_expression($abs_next, "sn)\$")) { $x->[1] = "unary" }
			elsif(is_expression($abs_prev, "^sn(") && is_expression($abs_next, "a(")) { $x->[1] = "lunary" }
			else {
				$x->[1] = "error";
			}
		}
		
		# методы: a method b
		# a unary method b
		# a method -b
		elsif($x->[1] eq "method") {
			my $is_expression = is_expression($prev, "au");

			if($is_expression && (
				is_expression($next, "a)")
				|| is_expression($next, "o") && do {
					my $abs_next = $ret->[$i+1];
					my $after_next = $ret->[$i+3];
					is_expression($abs_next, "s") && is_expression($after_next, "a(")
				}
			)) {}
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

# Подготавливаем таблицу приоритетов операторов
my %OP;
{
	my $i = 0;
	%OP = map { $i++; map { ($_ => $i) } grep {$_} split /\s+/, $_ } grep {$_} split /\n/, "
		-A +A
		unary A! A\$ A# A+ A-
		@
		^
		* /
		+ -
		method
		< > =
		not
		and
		or
		~A
		&
		|
		^A
		newline
	";
}

# приоритет оператора
sub prio { 
	my ($s, $op) = @_;
	
	my $f = $s->{lex} =~ /^[[:punct:]]/? do {
		my $r = $s->{type} eq "unary"? "A$s->{lex}": $s->{type} eq "lunary"? "$s->{lex}A": $s->{lex};
		my $x = $op->{$r};
		if(!defined $x) {
			$x = substr $s->{lex}, 0, 1;
			$x = $s->{type} eq "unary"? "A$x": $s->{type} eq "lunary"? "${x}A": $x;
			$x = $op->{$x};
			die "нет приоритета у оператора $r" if !defined $x;
		}
		$x
	}:
	$op->{$s->{type}};
	
	die "нет приоритета у метода $s->{lex}" if !defined $f;
	
	$f
};
sub is_op { my ($s) = @_; ref $s eq "HASH" && $s->{type} =~ /^(unary|lunary|method|newline)\z/n }
sub is_unary { my ($s) = @_; ref $s eq "HASH" && $s->{type} =~ /^(unary|lunary)/n  }


# разбирает код класса или метода и возвращает дерево разбора AST (грамматическинй ализатор)
sub to_tree {
	my ($self, $text) = @_;
	
	my $ret = $self->lex($text);

	# 1. убираем пробелы и строки перед методами и закрывающими скобками и повторяющиеся пустые строки
	my $line = 1;
	my $char = 1;
	my $prev_newline;
	my $remarks = [];
	my @R = map {
		
		die "$line:$char: syntax error `$_->[0]`" if $_->[1] eq "error";
		
		my $lex = {
			line => $line,
			char => $char,
			lex => $_->[0],
			type => $_->[1],
		};

		$lex->{prio} = prio($lex, \%OP), is_unary($lex)? ($lex->{unary} = 1): () if is_op($lex);

		$char += length $_->[0];

		$line++, $char = 1 if $_->[1] eq "newline";

		$_->[1] eq "space"? ():
		$_->[1] eq "remark"? do { push @$remarks, $lex; () }:
		$_->[1] eq "newline"? do { $prev_newline? (): do { $prev_newline = 1; $lex } }:
		do { $prev_newline = 0; $lex }
	} @$ret;
	
	# удаляем \n после { и перед }
	for(my $i=0; $i<@R; $i++) {
		splice @R, $i+1, 1 if $R[$i]{lex} =~ /^[\{\[\(]\z/ && $i+1<@R && $R[$i+1]{type} eq "newline";
		splice @R, $i, 1 if $R[$i]{type} eq "newline" && ($i+1<@R && ($R[$i+1]{lex} =~ /^[\}\]\)]\z/ || $R[$i+1]{type} eq "method") || $i+1==@R);
	}
	
	# 2. строим дерево опираясь на скобки
	my @K = my $root = [];
	my @I = $root; # множество скобок
	for my $r (@R) {
		if($r->{lex} =~ /^[\{\[\(]\z/) { my $new_sk = []; push @{$K[$#K]}, $new_sk; push @K, $new_sk; push @I, $new_sk; }
		elsif($r->{lex} =~ /^[\}\]\)]\z/) { pop @K }
		else { push @{$K[$#K]}, $r }
	}
	
	my %I = map { int($_) => 1 } @I;
	
	# 3. внутри скобок производим ранжировку по операторам
	#
	# a + b * -c - x
	# (a + (b * (-c))) - x
	
	my @S; my @T;
	
	my $in_T = sub { ::msg "in T", s_tree0($_[0]) if $DEBUG>1; push @T, $_[0] };
	my $from_T = sub { my $r = pop @T; die "from T - пусто" if !$r; ::msg "from T", s_tree0($r) if $DEBUG>1; $r };
	my $in_S = sub { ::msg "in S", s_tree0($_[0]) if $DEBUG>1; push @S, $_[0] };
	my $from_S = sub { my $r = pop @S; die "from S - пусто" if !$r; ::msg "from S", s_tree0($r) if $DEBUG>1; $r };
	
	my $shift_convolution = sub {	# сворачиваем все операторы в @S с меньшим приоритетом чем указанный и добавляем их в @T
		my ($prio1) = @_;
		my $s; my $p;
		while(@S && $S[$#S]->{prio} <= $prio1) {
			my $xop = $from_S->();
			
			my $y = $from_T->();
			$in_T->([$y, $xop]), next if $xop->{unary};
			
			my $x = $from_T->();
			# $x $xop $y: если $x - массив с бинарным оператором и приоритеты совпадают - то добавляем $xop $y к нему
			if(ref $y eq "ARRAY" and !exists $I{int $y} and @$y>2 and $xop->{prio} == $y->[1]->{prio}) {
				$in_T->([$x, $xop, @$y]);
			} elsif(ref $x eq "ARRAY" and !exists $I{int $x} and @$x>2 and $xop->{prio} == $x->[1]->{prio}) {
				$in_T->([@$x, $xop, $y]);
			} else {
				$in_T->([$x, $xop, $y]);
			}
		}
	};
	
	#::msg "R", s_tree0(\@R) if $DEBUG>0;
	#::msg "I", s_tree0($root) if $DEBUG>0;
	
	for my $I (reverse @I) {		# скобки
		::msg "in brackets", s_tree($I) if $DEBUG>1;
		::msg "in brackets0", s_tree0($I) if $DEBUG>1;
	
		for my $r (@$I) {	# операнды и операторы в скобках
			if(!is_op($r)) { $in_T->($r) } 		# если это операнд, то помещаем его в T
			elsif($r->{type} eq "lunary") { $in_S->($r) }
			else {
				::msg "prio", $r->{prio}, s_tree0($r) if $DEBUG>1;
				$shift_convolution->($r->{prio});
				$in_S->($r);
			}
		}
		$shift_convolution->(+"inf");
		
		die "\@S не пуст!" if @S;
		die "\@T пуст!" if !@T;
		die "\@T=".@T.">1!" if @T!=1;
		
		my $x = $from_T->();
		@$I = ref $x eq "ARRAY"? @$x: $x;
		
		#::msg "ex", s_tree0($root) if $DEBUG>0;
	}
	
	# # проставляем типы и объединяем многоарные методы, at put, например
	# $self->types($root, $who);
	# # уже с типами генерируем код на C
	# $self->morph($root, $who);
	
	$root
}

sub s_lex0 {
	ref $_[0] eq "ARRAY"? "[".@{$_[0]}."]": $_[0]->{type} eq "lunary"? " $_[0]->{lex}": $_[0]->{type} eq "unary"? ($_[0]->{lex} =~ /^[[:punct:]]/? $_[0]->{lex}: " $_[0]->{lex}"): $_[0]->{type} eq "method"? " $_[0]->{lex} ": $_[0]->{lex} 
}
sub s_lex { ref $_[0] eq "ARRAY"? "[".@{$_[0]}."]": "$_[0]->{lex}.$_[0]->{type}" }

sub s_tree {
	my ($tree) = @_;
	join " ", ref $tree eq "ARRAY"? ("( ", (map { s_tree($_) } @$tree), " )"): s_lex($tree)
}

sub s_tree0 {
	my ($tree) = @_;
	ref $tree eq "ARRAY"? join("", "(", (map { s_tree0($_) } @$tree), ")"): s_lex0($tree)
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


# компиллирует метод или описание класса
# для компилляции подгружаются описания файлов с диска
sub compile {
	my ($self, $text) = @_;
	
	# получаем AST:
	my $exp = $self->to_tree($text);
	
	if($text =~ s/^(\w+)[ \t]+subclass[ \t]+(\w+)[ \t]*(\n|$)//) {
		my ($class, $super) = ($2, $1);
		
	}
	else {
		
	}
	
	
	$self
}


1;