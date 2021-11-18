package Ninja::Jinnee::Perl;
# Плагин суперредактора Ninja

use common::sense;

use parent "Ninja::Role::Jinnee";


sub new {
	my $cls = shift;
	bless {
		INC => ["lib"],	# @INC
		@_,
	}, ref $cls || $cls;
}

#@category Списки

# возвращает множество в INC - список пакетов и список модулей в пакете [-]
sub package_list_info {
	my ($self) = @_;

	my @files;
	my @packages;
	my %package;
	my @nouname;
	
	for my $inc (@{$self->{INC}}) {
		for($self->ls($inc)) {
			my $name = substr $_, 1+length $inc;
			my $package = +{ section => "packages", inc => $inc, path => $_, name => $name };
			if(-d $_) {
				push @packages, $package;
				$package{$name} = 1;
			} else {
				$package->{name} =~ s!\.pm$!!;
				push @files, $package;
			}
		}
	}

	# Модули, что не имеют своих каталогов будут входить в пакет [-]
	for(@files) {
		if(exists $package{$_->{name}}) { push @packages, $_; }
		else { push @nouname, $_; }
	}
	
	return +{
		packages => [@nouname? {section => "packages", name => "[-]", nouname => 1}: (), sort { $a->{name} cmp $b->{name} } @packages],
		nouname => [sort { $a->{name} cmp $b->{name} } @nouname],
	}
}


# список пакетов
# классы в корне inc либо забрасываются в одноимённые пакеты, либо попадают в пакет [-]
sub package_list {
	my ($self) = @_;
	my $info = $self->package_list_info;
	@{$info->{packages}}
}

# список классов в указанном пакете
# рекурсивно обходит путь и строит все файлы
sub class_list {
	my ($self, $package) = @_;
	
	return map {
		$_->{section} = "classes";
		$_->{package} = $package;
	$_ } @{$self->package_list_info->{nouname}} if $package->{nouname};
	
	map { my $path = $_; my ($supername) = m!([^/]*)$!;
		-f $path? +{ path => $path, name => do { $supername =~ s!\.pm$!!; $supername } }:
		map { +{
			section => "classes",
			package => $package,
			path => $_,
			name => do {
				my $name = substr $_, 1+length $path;
				$name =~ s!\.[^\./]*$!!;
				$name =~ s!/!::!g;
				"${supername}::$name"
		} } } $self->lstree_files($path)
	}
	$package->{path}
}

# список категорий
sub category_list {
	my ($self, $class) = @_;
	
	my $path = $class->{path};
	
	local $_ = $self->file_read($path);
	
	my @cat;
	while(/^#\@category[ \t]+(.*?)[ \t]*$/gm) {
		push @cat, {section=>"categories", class=>$class, path=>$path, name=>$1};
	}
	# ∰ - три факториала в круге
	# Qiyeshipin Shengchanxuke logo.svg
	return {section=>"categories", class=>$class, path=>$path, name=>"§", header => 1}, @cat
}

# список методов
sub method_list {
	my ($self, $category) = @_;
	
	my $file = $self->file_read($category->{path});
	
	local $_;
	if($category->{header}) {
		$_ = $file =~ /^#\@category[ \t]+(.*?)[ \t]*$/m? $`: "";
	} else {
		my @cat; my $idx;
		while($file =~ /^#\@category[ \t]+(.*?)[ \t]*$/gm) {
			$idx = @cat if $1 eq $category->{name};
			push @cat, {pos => length($`), len => length($&), name => $1};
		}

		warn("Нет категории `$category->{name}`"), return if !defined $idx;

		my $from = $cat[$idx]{pos} + $cat[$idx]{len};
		$_ = substr $file, $from, ($idx+1 < @cat? $cat[$idx+1]{pos}: length $file) - $from;
	}
	
	my @methods;
	while(/^sub[ \t]+([\w:]+)/gm) {
		push @methods, { section => "methods", category => $category, name => $1 };
	}

	@methods
}


#@category Читатели

# возвращает номер строки и тело класса
sub class_get {
	my ($self, $class) = @_;
	
	my $file = $self->file_read($class->{path}); 
# "package $class->{name};
# # 
# use common::sense;

# sub new {
# my \$cls = shift;
# bless {		
	# \@_,
# }, ref \$cls || \$cls;
# }

# 1;";
	
	my ($new) = $file =~ m!^(.*?)(\nsub\b|\n#\@category\b|$)!s;
	
	return 1, $new;
}

# Возвращает номер строки и тело метода
sub method_get {
	my ($self, $method) = @_;
	
	my $file = $self->file_read($method->{category}{path}); 
	#"sub $method->{name} {\n\tmy (\$self) = \@_;\n\n\t\$self\n}\n";
	
	my $line = 1;
	my $pos = 0;
	my $is;
	while($file =~ m{
		(?<newline> \n )
		| ^sub \s+ (?<sub> [\w:]+ )
		| (?<endsub> ^\} .* \n? | \z)
	}gxmn) {
		if(exists $+{newline}) { $line++ }
		elsif(exists $+{endsub}) {
			return $line, substr $file, $pos, length($`) + length($&) - $pos if $is;
			$pos = length($`) + length($&);
		}
		elsif(exists $+{sub}) {
			$is = 1 if $+{sub} eq $method->{name};
			
			$line++ while $+{sub} =~ /\n/g;
		}
	}
	
	return 1, "";
}

#@category Писатели

# сохраняет и если нужно - переименовывает. Возвращает переименованный объект
sub class_put {
	my ($self, $class, $text) = @_;
	
	# замена текста заголовка
	my $file = $self->file_read($class->{path});
	$file =~ s!^(.*?)(\nsub\b|\n#\@category\b|$)!$text$2!s;
	$self->file_save($class->{path}, $file);
	
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


#@category Синтаксис

sub tags {
	my ($self) = @_;
	
	+{
		Alert        => [-foreground => "#0000ff"],
		BaseN        => [-foreground => "#8A2BE2"],
		BString      => [-foreground => "#008B8B"],
		Char         => [-foreground => "#4682B4"],
		Comment      => [-foreground => '#696969', -relief => 'raised'],
		DataType     => [-foreground => "#C71585"],
		DecVal       => [-foreground => "#BC8F8F"],
		Error        => [-background => '#FF0000'],
		Float        => [-foreground => "#ff1493"],
		Function     => [-foreground => "#4169E1"],
		IString      => [-foreground => "#00008B"],
		Keyword      => [-foreground => "#1E90FF"],
		Normal       => [],
		Operator     => [-foreground => "#ffa500"],
		Others       => [-foreground => "#b03060"],
		RegionMarker => [-foreground => "#96b9ff"],
		Reserved     => [-foreground => "#9b30ff"],
		String       => [-foreground => "#5F9EA0"],
		Variable     => [-foreground => "#DC143C"],
		Warning      => [-foreground => "#0000ff"],
		
		
		# number => [-foreground => '#8A2BE2'],
		# string => [-foreground => '#008B8B'],
		
		# variable => [-foreground => '#C71585'],
		# class => [-foreground => '#C71585'],
		# method => [-foreground => '#4169E1'],
		# unary => [-foreground => '#BC8F8F'],
		
		# operator => [-foreground => '#8B0000'],
		# prefix => [-foreground => '#008080'],
		# postfix => [-foreground => '#1E90FF'],
		# compare_operator => [-foreground => '#DC143C'],
		# logic_operator => [-foreground => '#C71585'],
		
		# staple => [-foreground => '#4682B4'],
		# bracket => [-foreground => '#5F9EA0'],
		# brace => [-foreground => '#00008B'],
		
		# punct => [-foreground => '#00008B'],
		# remark => [-foreground => '#696969', -relief => 'raised'],
		
		# error => [-background => '#FF0000'],
	}
}

sub color {
	my ($self, $who, $text) = @_;

	use Ninja::Ext::Color;
	my $color = Ninja::Ext::Color->new;
	
	my $lang = $color->by($who->{path} // $who->{category}{path});

	$color->color($lang => $text);
}

# считывает файл синтаксиса (*.syn)
sub syn {
	my ($self, $path) = @_;
	
	open my $f, "<:utf8", $path or die "Не могу открыть `$path`. Причина: $!";
	
	while(<$f>) {
		next if /^\s*#/;	# комментарий
		# if /^\s*key\s+/;
		
		die "Строка $. файла `$path` не распознана!";
	}
	
	close $f;
	
	$self
}

1;