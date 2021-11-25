package Ninja::Monitor::Sector;
# Драйвер секционального редактора Ninja для наблюдения за участками файловой системы

use common::sense;

use parent "Ninja::Role::Monitor";

use Ninja::Ext::File;


sub new {
	my $cls = shift;
	bless {
		INC => ["."],	# @INC
		@_,
	}, ref $cls || $cls;
}

#@category Списки

# Обходит указанную фс и создаёт списки пакетов и классов
sub scan {
	my ($self, $sub_path) = @_;
	
	my %classes;	# пакет -> [класс...]
	
	my %dir; my @files;
	for my $inc (@{$self->{INC}}) {
		my $incf = Ninja::Ext::File->new("$inc$sub_path");
		
		my ($dirs, $files) = $incf->lstree;
		$classes{$_->path} //= [] for @$dirs;
		
		push @files, @$files;
	}
	
	for my $file (@$files) {
		my $pack = $file->path_without_ext;
		if(exists $classes{$pack}) {
			push @{$classes{$pack}}, $file;
		} else {
			my $package = $file->dir;
			push @{$classes{$package}}, $file;
		}
	}

	return \%classes;
}


# список пакетов
# классы в корне inc либо забрасываются в одноимённые пакеты, либо попадают в пакет [-]
sub package_list {
	my ($self) = @_;
	my $classes = $self->scan;

	my $root = delete $classes{""};

	# ¤	
	return $root? {root=>1, section=>"packages", name=>"§", path=>""}: (), map {+{
		section => "packages",
		name => $_,
		path => $_,
	}} sort keys %$classes;
}

# список классов в указанном пакете
# рекурсивно обходит путь и строит все файлы
sub class_list {
	my ($self, $package) = @_;
	
	my $file = Ninja::Ext::File->new($package->{path});
	my ($dirs, $files) = $file->lsx;
	my ($d1, $f1);
	my $dir = $file->dir;
	($d1, $f1) = $file->new($dir)->lsx if defined $dir;
	
	map { +{
		section => "classes",
		package => $package,
		path => $_,
		name => do {
			my $name = $_;
			$name =~ s!\.[^\./]*$!!;
			$name =~ s!/!.!g;
			$name
		}
	}}
	sort { $a cmp $b }
	(grep {!exists $dirs{$_}} keys %$files),
	map {$_->path} grep {$_->path_without_ext eq $dir} values %$f1;
}

# список категорий
sub category_list {
	my ($self, $class) = @_;
	
	my $path = $class->{path};
	
	my $jinnee = $self->jinnee($path);
	my $file = Ninja::Ext::File->new($path);
	
	my @A = $jinnee->parse($file);
	return if !@A;
	
	unshift @A, {section=>"categories", name=>"§", class=>$class} if $A[0]{section} eq "methods";
	
	for my $entity () {
		last if ;
	}
	
	# local $_ = $self->file_read($path);
	
	# my @cat;
	# while(/^#\@category[ \t]+(.*?)[ \t]*$/gm) {
		# push @cat, {section=>"categories", class=>$class, path=>$path, name=>$1};
	# }
	# # ∰ - три факториала в круге
	# # Qiyeshipin Shengchanxuke logo.svg
	# return {section=>"categories", class=>$class, path=>$path, name=>"§", header=>1}, @cat
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



1;