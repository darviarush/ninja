package Ninja::Role::Jinnee;
# Базовый класс для языка

use common::sense;

sub new {
	my $cls = shift;
	bless {		
		@_,
	}, ref $cls || $cls;
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
	
	unlink($path) || die("Нельзя удалить файл `$path`. Причина: $!"), return if !-d $path;
	
	$self->rmtree($_) for $self->ls($path);
	rmdir $path;
}

sub mkpath {
	my ($self, $path) = @_;
	mkdir $`, 0755 while $path =~ /\//g;
}

sub file_save {
	my ($self, $path, $body) = @_;
	my $f;
	open $f, ">", $path or die "Не могу создать `$path`. Причина: $!";
	print $f $body;
	close $f;
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

1;