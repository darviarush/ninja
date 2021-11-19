package Ninja::Ext::File;
# Путь в файловой системе

use common::sense;

use Time::HiRes qw//;

# конструктор
sub new {
	my ($cls, $path) = @_;
	bless {
		path => $path,
	}, ref $cls || $cls;
}

#@category Пути

sub path { my ($self) = @_; $self->{path} }
sub isdir { my ($self) = @_; -d $self->{path} }
sub isfile { my ($self) = @_; -f $self->{path} }
sub mod { my ($self) = @_; (stat $self->{path})[2] & 07777 }
sub mtime { my ($self) = @_; (Time::HiRes::stat $self->{path})[10] }
sub dir { my ($self) = @_; $self->{path} =~ m!/[^/]*$!? $`: undef }
sub file { my ($self) = @_; my ($file) = $self->{path} =~ m!([^/]+)$!; $file }
sub name { my ($self) = @_; my ($name) = $self->{path} =~ m!([^/]+)(?:\.[^/\.]*)?$!; $name }
sub ext { my ($self) = @_; my ($ext) = $self->{path} =~ m!\.([^/\.]*)$!; $ext }
sub path_without_ext { my ($self) = @_; $self->{path} =~ m!\.([^/\.]*)$! && $` }

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

my $SGN_FROM = "sub { my (\$self) = \@_; my $x = $self->{path}; \$x =~ y/$SIGN_FROM/$SIGN_TO/; \$x }";
my $SGN_TO = "sub { my (\$self) = \@_; \$x =~ y/$SIGN_TO/$SIGN_FROM/; \$x }";

*escape = eval $SGN_FROM;
*unescape = eval $SGN_TO;

#@category Файлы

# список файлов в папке, кроме .. и .
sub ls {
	my ($self) = @_;
	
	my $path = $self->{path};
	
	opendir my $dir, $path or die "Не открыть `$path`: $!";
	my @ls;
	while(defined(my $file = readdir $dir)) {
		utf8::decode($file) if !utf8::is_utf8($file);
		
		push @ls, "$path/$file" if $file ne "." and $file ne "..";
	}
	closedir $dir;
	
	map { $self->new($_) } sort @ls;
}

# рекурсивно возвращает каталоги
sub lstree_dirs {
	my ($self) = @_;
	my @S = $self;
	my @paths;
	while(@S) {
		for(pop(@S)->ls) {
			push(@S, $_), push @paths, $_ if -d $_->{path};
		}
	}
	return @paths;
}

# рекурсивно возвращает файлы
sub lstree_files {
	my ($self) = @_;
	my @S = $self;
	my @paths;
	while(@S) {
		for(pop(@S)->ls) {
			if(-d $_->{path}) { push @S, $_ } else { push @paths, $_ }
		}
	}
	return @paths;
}

# Рекурсивно возвращает файлы и каталоги
sub lstree {
	my ($self) = @_;
	my @S = $self;
	my $files = [];
	my $dirs = [];
	while(@S) {
		for(pop(@S)->ls) {
			if(-d $_->{path}) {push @S, $_; push @$files, $_} else {push @$dirs, $_}
		}
	}
	return $dirs, $files;
}

sub rmtree {
	my ($self) = @_;
	
	unlink($self->path) || die("Нельзя удалить файл `$self->{path}`. Причина: $!"), return $self if !$self->isdir;
	
	$_->rmtree for $self->ls;
	rmdir $self->{path};
	
	$self
}

# копирует файл
sub copy {
	my ($self, $to) = @_;
	my $from = $self->path;
	$to = $to->{path} if ref $to;
	
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
	my ($self, $to) = @_;
	
	$to = $to->{path} if ref $to;
	
	$self->copy($to), return $self if !-d $to;
	
	mkdir $to, $self->mod;
	$_->mvtree("$to/${\ $self->file}") for $self->ls;
	
	$self
}

sub mkpath {
	my ($self) = @_;
	local $_ = $self->{path};
	mkdir $`, 0755 while /\//g;
	$self
}

# сохраняет файл 
sub write {
	my ($self, $text) = @_;
	$self->mkpath;
	my $f;
	open $f, ">", $self->path or die "Не могу создать `$self->{path}`. Причина: $!";
	print $f $text;
	close $f;
	$self
}

# подгружает или создаёт файл
sub load {
	my ($self, $template) = @_;
	my $f;
	my $path = $self->{path};
	open $f, "<:utf8", $path and do { read $f, my $buf, -s $f; close $f; $buf }
	or do { # если $buf выше будет пустой, то выполнится и эта ветвь
		$self->mkpath;
		open $f, ">:utf8", $path or die "Не могу создать `$path`. Причина: $!";
		print $f $template;
		close $f;
		::p my $x="_create $path";
		$template
	}
}

sub read {
	my ($self, $path, $encode) = @_;
	$encode //= 'utf8';
	open my $f, "<:encoding($encode)", $path or die "Не могу открыть `$path`. Причина: $!";
	read $f, my $buf, -s $f;
	$buf
}

=pod
рекурсивно обходит каталог path запуская на каждом подходящем файле ok и progress через каждые 

* dirs - путь. Может быть массивом

Параметры:

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
sub find_set {
	my ($self, $dirs, %args) = @_;
	$self->{file_find_param} = {
		S => ref $dirs? $dirs: [$dirs],
		%args
	};
	$self
}

sub find {
	my ($self) = @_;
	
	my $F = $self->{file_find_param};
	
	my $S = $F->{S};
	my $notin = $F->{notin};
	my $include = $F->{include};
	my $exclude = $F->{exclude};
	my $time = Time::HiRes::time() + $F->{after} // 0.01;
	my $R;
	
	while(@$S) {
		my $dir = pop @$S;
		
		$F->{dirs}++;
		
		for my $file ($self->new($dir)->ls) {
			my $path = $file->{path};
			push(@$S, $file), next if $file->isdir and !($notin and $path =~ $notin);
			$F->{files}++;
			$F->{files_ok}++, push @$R, $file if (defined $include and $path =~ $include) and !($exclude and $path =~ $exclude);
		}
		
		return @$R? $R: @$S? []: 0 if $time < Time::HiRes::time();
	}
	
	return @$R? $R: 0;
}

# текстовый поиск в файлах
# параметры те же, что и в file_find и
# * re - регулярка для поиска в файле
sub find_text {
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


1;