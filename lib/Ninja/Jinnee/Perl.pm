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

sub package_list_info {
	my ($self) = @_;

	my @files;
	my @packages;
	my %package;
	my @nouname;
	
	for my $inc (@{$self->{INC}}) {
		for($self->ls($inc)) {
			my $name = substr $_, 1+length $inc;
			my $package = +{ path => $_, name => $name };
			if(-d $_) {
				push @packages, $package;
				$package{$name} = 1;
			} else {
				$package->{name} =~ s!\.pm$!!;
				push @files, $package;
			}
		}
	}

	for(@files) {
		if(exists $package{$_->{name}}) { push @packages, $_; }
		else { push @nouname, $_; }
	}
	
	return +{
		packages => [@nouname? {name => "[-]", nouname => 1}: (), sort { $a->{name} cmp $b->{name} } @packages],
		nouname => \@nouname,
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
	
	my $info = $self->package_list_info;
	
	return @{$info->{nouname}} if $package->{nouname};
	
	map { my $path = $_; my ($supername) = m!([^/]*)$!;
		-f $path? +{ path => $path, name => do { $supername =~ s!\.pm$!!; $supername } }:
		map { +{ path => $_, name => do {
			my $name = substr $_, 1+length $path;
			$name =~ s!\.[^\./]*$!!;
			$name =~ s!/!::!g;
			"${supername}::$name"
		} } } grep { -f $_ } $self->find($path)
	} 
	$package->{all}? (map { $self->ls($_) } @{$self->{INC}}): 
	$package->{path}
}

# список категорий
sub category_list {
	my ($self, $class) = @_;
	
	my $path = $class->{path};
	
	local $_ = $self->file_read($path);
	
	my @cat;
	while(/^#\@category[ \t]+(.*?)[ \t]*$/gm) {
		push @cat, {path=>$path, name=>$1};
	}
	
	@cat
}

# список методов. $category может быть '*'
sub method_list {
	my ($self, $category) = @_;
	
	local $_ = $self->file_read($category->{path});
	
	($_) = /^#\@category[ \t]+\E$category->{name}\R[ \t]*$(.*?)(^#category\b|\z)/ms if !$category->{all};
	
	map { my $path = $_;
		map { +{ path => $_, name => substr $_, 1+length($path), -2 } } grep { /\.\$\z/ } $self->ls($path)
	} $category->{all}? $self->ls($category->{path}): $category->{path}
}


#@category Читатели

# возвращает номер строки и тело класса
sub class_get {
	my ($self, $class) = @_;
	
	my $file = $self->file_load($class->{path}, "package $class->{name};
# 
use common::sense;

sub new {
my \$cls = shift;
bless {		
	\@_,
}, ref \$cls || \$cls;
}

1;");
	
	my ($class) = $file =~ m!^(.*?)(\nsub\b|$)!s;
	
	return 1, $self->color($class);
}

# Возвращает номер строки и тело метода раскрашенное разными цветами
sub method_get {
	my ($self, $method) = @_;
	return 1, $self->color( $self->file_load("$method->{path}", "$method->{name}\n\n") );
}

#@category Синтаксис

sub tags {
	my ($self) = @_;
	
	+{
		number => [-foreground => '#8A2BE2'],
		string => [-foreground => '#008B8B'],
		
		variable => [-foreground => '#C71585'],
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

sub color {
	my ($self, $text) = @_;

	my $prev = 0;
	my $ret = [];

	my $re_op = '[-+*/^%$?!<>=.:,;|&\\#]';

	my $re = qr{
		(?<remark> ([\ \t]|^) \# .* ) |
		
		(?<number> [+-]?\d+(\.\d+)? ) |
		(?<string> "(\\"|.)*" | '(\\'|.)*' ) |
		
		(?<class> \b [A-Z]\w+ \b) |
		(?<variable> \b [a-zA-Z] \b) |
		
		(?<method> \b [a-z]\w+ \b) |
		
		(?<logic_operator> \b (not|and|or) \b ) |
		(?<compare_operator> [<>=]$re_op* ) |
		(?<operator> $re_op+ ) |
		
		(?<staple> [()] ) |
		(?<bracket> [\[\]] ) |
		(?<brace> [{}] ) |
		
		(?<punct> [|,;] ) |
		
		(?<newline> \n ) |
		(?<space> \s+ )
	}xmn;
	while($text =~ /$re/go) {
		my $point = length $`;
		if($point - $prev != 0) {
			push @$ret, [substr($`, $prev, $point), "error"];
		}
		$prev = $point + length $&;
		
		my ($tag, $lexem) = each %+;
		push @$ret, [$lexem, $tag];
	}
	
	if($prev != length $text) {
		push @$ret, [substr($text, $prev), "error"];
	}	
	
	$ret
}

1;