package Ninja::Role::Jinnee;
# Базовый класс для языка

use common::sense;

sub new {
	my $cls = shift;
	bless {		
		@_,
	}, ref $cls || $cls;
}

#@category Секции

sub sections { return qw/packages classes categories methods/ }
sub singular { return qw/package class category method/ }

our %SINGULAR = map { ((sections())[$_], (singular())[$_]) } 0..3;
sub sin { $SINGULAR{$_[1]} }


#@category Сущности

# извлечение класса или метода
sub get {
	my ($self, $who) = @_;
	if($who->{section} eq "classes") { $self->class_get($who) }	else { $self->method_get($who) }
}

# установка класса или метода
sub put {
	my ($self, $who, $text) = @_;
	if($who->{section} eq "classes") { $self->class_put($who, $text) }	
	else { $self->method_put($who, $text) }
}

# сравнение объектов
sub equal {
	my ($self, $who1, $who2) = @_;
	scalar($who1 == $who2 || $who1->{path} eq $who2->{path})
}

#@category Переименование / в системных путях

my %SIGN = (
	chr 0x00 => chr 0x2400,	# NUL
	chr 0x01 => chr 0x2401,	# SOH
	chr 0x02 => chr 0x2402,	# STX
	chr 0x03 => chr 0x2403,	# ETX
	chr 0x04 => chr 0x2404,	# EOT
	chr 0x05 => chr 0x2405,	# ENQ
	chr 0x06 => chr 0x2406,	# ACK
	chr 0x07 => chr 0x2407,	# BEL
	chr 0x08 => chr 0x2408,	# BS
	chr 0x09 => chr 0x2409,	# HT
	chr 0x0A => chr 0x240A,	# LF
	chr 0x0B => chr 0x240B,	# VT
	chr 0x0C => chr 0x240C,	# FF
	chr 0x0D => chr 0x240D,	# CR
	chr 0x0E => chr 0x240E,	# SO
	chr 0x0F => chr 0x240F,	# SI
	chr 0x10 => chr 0x2410,	# DLE
	chr 0x11 => chr 0x2411,	# DC1
	chr 0x12 => chr 0x2412,	# DC2
	chr 0x13 => chr 0x2413,	# DC3
	chr 0x14 => chr 0x2414,	# DC4
	chr 0x15 => chr 0x2415,	# NAK
	chr 0x16 => chr 0x2416,	# SYN
	chr 0x17 => chr 0x2417,	# ETB
	chr 0x18 => chr 0x2418,	# CAN
	chr 0x19 => chr 0x2419,	# EM
	chr 0x1A => chr 0x241A,	# SUB
	chr 0x1B => chr 0x241B,	# ESC
	chr 0x1C => chr 0x241C,	# FS
	chr 0x1D => chr 0x241D,	# GS
	chr 0x1E => chr 0x241E,	# RS
	chr 0x1F => chr 0x241F,	# US
	chr 0x7F => chr 0x2421,	# DEL

	'/' => chr 0x2215, # 2044
	'<' => chr 0x2329, # 227A, 2039
	'>' => chr 0x232A, # 227B, 203A
	':' => chr 0x2236,
	'"' => chr 0x2033, # 0x201D
	'\\' => chr 0x2216,
	'|' => chr 0x2223, # 23D0
);

sub _ox { sprintf "\\x{%X}", ord $_[0] }
my $SIGN_FROM = join "", map { _ox($_) } sort keys %SIGN;
my $SIGN_TO = join "", map { _ox($SIGN{$_}) } sort keys %SIGN;

my $SGN_FROM = "sub { my (\$self, \$x) = \@_; \$x =~ y/$SIGN_FROM/$SIGN_TO/; \$x }";
my $SGN_TO = "sub { my (\$self, \$x) = \@_; \$x =~ y/$SIGN_TO/$SIGN_FROM/; \$x }";

*escape = eval $SGN_FROM;
*unescape = eval $SGN_TO;

# $SIGN_FROM = join "", sort keys %SIGN;
# $SIGN_TO = join "", map {$SIGN{$_}} sort keys %SIGN;

# my $r1 = Ninja::Role::Jinnee::escape("", $SIGN_FROM);
# my $r2 = Ninja::Role::Jinnee::unescape("", $SIGN_TO);
# ::msg "r1", $r1;
# ::msg "r2", $r2;

# if($r1 eq $SIGN_TO) {print "ok!\n"} else {print "fail!\n"}
# if($r2 eq $SIGN_FROM) {print "ok!\n"} else {print "fail!\n"}

#@category Файлы

# список файлов в папке, кроме .. и .
sub ls {
	my ($self, $path) = @_;
	
	opendir my $dir, $path or die "Не открыть `$path`: $!";
	my @ls;
	while(defined(my $file = readdir $dir)) {
		utf8::decode($file) if !utf8::is_utf8($file);
		
		push @ls, "$path/$file" if $file ne "." and $file ne "..";
	}
	closedir $dir;
	
	sort @ls;
}

# Рекурсивно возвращает файлы
sub lstree_files {
	my ($self, $path) = @_;
	my @S = $path;
	my @paths;
	while(@S) {
		for($self->ls(pop @S)) {
			if(-d) { push @S, $_ } else { push @paths, $_ }
		}
	}
	return @paths;
}

sub rmtree {
	my ($self, $path) = @_;
	
	unlink($path) || die("Нельзя удалить файл `$path`. Причина: $!"), return $self if !-d $path;
	
	$self->rmtree($_) for $self->ls($path);
	rmdir $path;
	
	$self
}

sub file_copy {
	my ($self, $from, $to) = @_;
	
	rename $from, $to or do {
		undef $!;
		open my $f, "<:raw", $from or die "Нельзя скопировать файл `$from` в `$to`. Причина в файле: $!";
		open my $o, ">:raw", $to or do { close $f; die "Нельзя скопировать файл `$from` в `$to`. Причина в назначении: $!" };
		while(read $f, my $buf, 1024*1024) { print $o $buf; }
		close $f;
		close $o;
	};
	
	$self
}

sub mvtree {
	my ($self, $from, $to) = @_;
	$self->file_copy($from, $to), return $self if !-d $to;
	
	mkdir $to, (stat $from)[2] & 07777;
	$self->mvtree($_, do { my ($file) = m!([^/]+)$!; "$to/$file" }) for $self->ls($from);
	
	$self
}

sub mkpath {
	my ($self, $path) = @_;
	mkdir $`, 0755 while $path =~ /\//g;
	$path
}

sub file_save {
	my ($self, $path, $body) = @_;
	$self->mkpath($path);
	my $f;
	open $f, ">", $path or die "Не могу создать `$path`. Причина: $!";
	print $f $body;
	close $f;
	$self
}

# подгружает или создаёт файл
sub file_load {
	my ($self, $path, $template) = @_;
	my $f;

	open $f, "<:utf8", $path and do { read $f, my $buf, -s $f; close $f; $buf }
	or do { # если $buf выше будет пустой, то выполнится и эта ветвь
		$self->mkpath($path);
		open $f, ">:utf8", $path or die "Не могу создать `$path`. Причина: $!";
		print $f $template;
		close $f;
		::p my $x="_create $path";
		$template
	}
}

sub file_read {
	my ($self, $path, $encode) = @_;
	$encode //= 'utf8';
	open my $f, "<:encoding($encode)", $path or die "Не могу открыть `$path`. Причина: $!";
	read $f, my $buf, -s $f;
	$buf
}

=pod
рекурсивно обходит каталог path запуская на каждом подходящем файле ok и progress через каждые 
Параметры:
* path - путь. Может быть массивом
* notin - регулярка для подкаталогов в которые входить не надо
* include - маска для файлов которые ищем
* exclude - исключающая маска для файлов
* ok - обработчик найденного файла
* after - останавает поиск через это количество секунд, если ничего не найдено
а если найдено - возвращается сразу

Возвращает ["path",...], [] (был остановлен after) или 0 (что означает конец).

Использование:

	$self->file_find_set(".");
	while(my $f = $self->file_find) { ... }
=cut
sub file_find_set {
	my ($self, $dirs, %args) = @_;
	$self->{file_find_param} = {
		S => ref $dirs? $dirs: [$dirs],
		%args
	};
	$self
}

sub file_find {
	my ($self) = @_;
	
	my $F = $self->{file_find_param};
	
	my $S = $F->{S};
	my $notin = $F->{notin};
	my $include = $F->{include};
	my $exclude = $F->{exclude};
	use Time::HiRes;
	my $time = Time::HiRes::time() + $F->{after} // 0.01;
	my $R;
	
	while(@$S) {
		my $dir = pop @$S;
		
		$F->{dirs}++;
		
		for my $path ($self->ls($dir)) {
			push(@$S, $path), next if -d $path and !($notin and $path =~ $notin);
			$F->{files}++;
			$F->{files_ok}++, push @$R, $path if $path =~ $include and !($exclude and $path =~ $exclude);			
		}
		
		return @$R? $R: @$S? []: 0 if $time < Time::HiRes::time();
	}
	
	return @$R? $R: 0;
}

# текстовый поиск в файлах
# параметры те же, что и в file_find и
# * re - регулярка для поиска в файле
sub file_find_text {
	my ($self, $dirs, %a) = @_;

	my $ok = $a{ok};
	my $re = delete $a{re};
	$a{ok} = sub {
		my ($path) = @_;
		my $f = $self->file_read($path);
		return if $f !~ /(?=)$re/;
		
		my $x = length $`;
		# подсчитываем на какой это строке
		my $lineno = 0;
		my $pos;
		$pos = length($`), $lineno++ while $f =~ /\n/g && length($`) < $x;
		
		# получаем строку
		my ($line) = $f =~ /^.{$pos}([^\n]*)/s;
		
		$ok->(lineno => $lineno, charno => $x - $pos, line => $line, text => $f, path => $path, offset => $x);
	};
	$self->file_find($dirs, %a);
}

#@category Поиск и замена

# устанавливает параметры поиска
sub find_set {
	my ($self, $re, $where) = @_;
	$self->{find_param} = {
		re => $re,
		S => [$where // $self->package_list],
		result => [],
	};
	$self
}

# осуществляет поиск до первого срабатывания или пока не выйдет время
sub find {
	my ($self) = @_;
	
	my $A = $self->{find_param};
	my $S = $A->{S};
	
	my $time = Time::HiRes::time() + $A->{after} // 0.01;
	
	while(@$S) {
		my $who = pop @$S;
		
		my ($line_start, $text) = ();
		
		if($who->{section} eq "packages") {
			push @$S, $self->class_list($who);
		}
		elsif($who->{section} eq "classes") {
			push @$S, $self->category_list($who);
			($line_start, $text) = $self->class_get($who);
		}
		elsif($who->{section} eq "categories") {
			push @$S, $self->method_list($who);
		}
		else {
			($line_start, $text) = $self->method_get($who);
		}
		
		if(defined $text) {
			my $re = $A->{re};
			my @R;
			my $lex;
			my $i;
			my $where;

			while($text =~ /()$re/g) {
				my $offset = length $`;
				my $limit = $offset + length $&;
				$lex //= $self->color_ref($who, $text);

				# на какую лексему приходится начало выделения
				$i++ while $i<$#$lex && $lex->[$i+1]{offset} <= $offset;
				# и конец:
				my $j = $i;
				$j++ while $j<@$lex && $lex->[$j]{limit} < $limit;
				
				my $line1 = $lex->[$i]{line};
				my $char1 = $lex->[$i]{char};
				my $line2 = $lex->[$j]{line_end};
				my $char2 = $lex->[$j]{char_end};
				
				# выбираем все лексемы находящиеся на строке начала выделения
				my $n = $lex->[$i]{line};
				my $k = $i; my $m = $i;
				$k-- while $k>0 && $lex->[$k-1]{line} == $n;
				$m++ while $m<$#$lex && $lex->[$m+1]{line} == $n;
				
				$m-- if $lex->[$m]{lex} eq "\n";
				
				my $line = [map { my $t=$lex->[$_]{tag}; [$lex->[$_]{lex}, $t eq "space"? (): $t] } $k..$m];
				
				my $file = $who->{section} eq "methods"? 
					[[$who->{category}{class}{name}, 'class'], [" "], [$who->{name}, "method"]]:
					[[$who->{name}, "class"]];
				push @$file, [" "], [$line_start + $n - 1, "number"];

				unshift(@$line, ["\n"]), unshift @$file, ["\n"] if @{$A->{result}} + @R > 0;
				
				push @R, {
					select => [$offset - $lex->[$k]{offset},
								$lex->[$m]{limit} < $limit? $lex->[$m]{limit}: 
									$limit - $lex->[$k]{offset}],
					select_in_text => ["$line1.$char1", "$line2.$char2"],
					line => $line,
					file => $file,
					who => $who,
				};				
				
				$i = $j;
			}
			
			push(@{$A->{result}}, @R), return \@R if @R;
		}
		
		return @$S? []: 0 if $time < Time::HiRes::time();
	}
	
	0
}


#@category Подсветка синтаксиса

sub color_ref {
	my ($self, $who, $text) = @_;

	my $line = 1;
	my $char = 0;
	my $offset = 0;
	[ map { 
		my $r = {
			line => $line,
			char => $char,
			lex => $_->[0],
			tag => $_->[1], 
			offset => $offset,
			limit => $offset + length($_->[0]),
		}; 
		
		$offset += length $_->[0];
		$char += length $_->[0];
		$char = 0, $line++ while $_->[0] =~ /\n/g;
		
		$r->{line_end} = $line;
		$r->{char_end} = $char;
		
		$r 
	} @{$self->color($who, $text)} ];
}


1;