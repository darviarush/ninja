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

#@category Переименование / в системных путях

my $DIVIDE_SIGN = chr 0x2215;

# эскейпит часть пути в котором не должно быть слеша
# заменяет / на аналогичный символ юникода (U+2215)
sub escape {
	my ($self, $path) = @_;
	$path =~ s!/!$DIVIDE_SIGN!oge;
	$path
}

# заменяет юникодовский знак деления (U+2215) на слеш
sub unescape {
	my ($self, $path) = @_;
	$path =~ s!$DIVIDE_SIGN!/!g;
	$path
}

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

sub find {
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
		return if $f !~ $re;
		
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