package Ninja::Monitor::Sector;
# Драйвер секционального редактора Ninja для наблюдения за участками файловой системы

use common::sense;

use parent "Ninja::Role::Monitor";

use Ninja::Ext::File qw/f/;


sub new {
	my $cls = shift;
	bless {
		INC => ["."],		# @INC
		EXC => ["./.git"],	# сюда не заходим
		@_,
	}, ref $cls || $cls;
}

#@category Списки

# список пакетов
# классы в корне inc либо забрасываются в одноимённые пакеты, либо попадают в пакет [-]
sub package_list {
	my ($self) = @_;
	
	#$root? {root=>1, section=>"packages", name=>"[§]"}
	my %x;
	for my $inc (@{$self->{INC}}) {
		my ($D, $F) = f($inc)->lstree($self->{EXC});
		$x{substr $_->dir, length($inc)+1}++ for @$F;
	}
	
	map {
		+{
			section => "packages",
			name => $_ eq ""? "[§]": $_,
			path => $_,
		}
	} sort keys %x;
}

# список классов в указанном пакете
sub class_list {
	my ($self, $package) = @_;
	
	my $subpath = (length($package->{path})? "/": "") . $package->{path};
	
	map {
		my $inc = $_;
		my $len = length($inc)+1;
		map {+{
			section => "classes",
			package => $package,
			path => $_->{path},
			inc => $inc,
			name => $_->name,
		}} grep { -f $_->{path} } f($inc . $subpath)->ls;
	} @{$self->{INC}};
}

# список категорий
sub category_list {
	my ($self, $class) = @_;
	
	my $file = f $class->{path};
	my $x = $self->jinnee($file)->parse($file->read);
	
	my $order = sub { my ($cat) = @_; $cat->{$a}->{""}{from} <=> $cat->{$b}->{""}{from} };
	
	map { my $clss = $x->{$_}; my $pkg = $_;
		map { my $cats = $cls->{$_}; my $cn=$_;
			map {+{section=>"categories", class=>$class, name=>$_, p=>$pkg, c=>$cn}} 
				sort {$order->($cats)} keys %$cats
		} sort {$order->($clss)} keys %$clss
	} sort {$order->($x)} keys %$x;
}

# список методов
sub method_list {
	my ($self, $category) = @_;

	my ($pack, $cname, $class, $name) = @$category{qw/p c class name/};
	my $file = f $class->{path};
	my $x = $self->jinnee($file)->parse($file->read);

	my $cat = $x->{$pack}{$cname}{$name};

	map {+{section=>"methods", category=>$category, name=>$_}}
		sort { $cat->{$a}{from} <=> $cat->{$b}{from} }
		grep { $_ ne "" }
		keys %$cat
}


#@category Читатели

# возвращает номер строки и заголовок класса
sub class_get {
	my ($self, $class) = @_;	
	
	my $file = f $class->{path};
	my $x = $self->jinnee($file)->parse(my $code = $file->read);
	
	my ($pack) = sort {$a->{""}{from} <=> $b->{""}{from}} values %$x;
	my ($cls) = sort {$a->{""}{from} <=> $b->{""}{from}} values %$pack;
	
	return 1, substr $code, $cls->{from}, $cls->{end};
}

# строка
sub _line {
	my ($code, $from) = @_;
	
	my $line = 1;
	while($code =~ /\n/g) {
		last if length($`) > $from;
		$line++;
	}
	
	$line
}

# Возвращает номер строки и тело метода
sub method_get {
	my ($self, $method) = @_;
	my $category = $method->{category};
	my ($pack, $cname, $class, $name) = @$category{qw/p c class name/};
	my $file = f $class->{path};
	my $x = $self->jinnee($file)->parse($file->read);
	
	
	return _line($code, $from), substr($code, $from, $end - $from);
}

#@category Писатели

# сохраняет и если нужно - переименовывает. Возвращает переименованный объект
sub class_put {
	my ($self, $class, $text) = @_;
	
	my ($code, $end, $A) = $self->_class_get($class);

	# замена текста заголовка
	$code =~ s/^(.{$end})/$text/s;
	
	f($class->{path})->write($code);

	#$self->jinnee($class)->;

	# переименование файла класса по пакету
	if($text =~ /^package\s+([\w:]+)/) {
		my $path = $1;
		my ($new_name) = $path =~ /(\w+)$/;
		my ($name) = $class->{path} =~ /(?:^|\/)(\w+)\.[^.]+$/;
		if($name ne "" and $new_name ne "" and $name ne $new_name) {
			$path = $class->{path};
			$path =~ s/$name(\.[^.]+)$/$new_name$1/;
			undef $!;
			rename $class->{path}, $path and do {
				$class = {%$class, name => $new_name, path => $path};
			};
		}
	}
	
	return $class;
}



1;