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
		} } } grep { -f $_ } $self->find($path)
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
	
	@cat
}

# список методов
sub method_list {
	my ($self, $category) = @_;
	
	local $_ = $self->file_read($category->{path});
	
	($_) = /^#\@category[ \t]+\Q$category->{name}\E[ \t]*$(.*?)(^#category\b|\z)/ms or do {
		warn "Категория $category->{name} в $category->{path} отсутствует";
		return;
	};
	
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
	
	my $file = $self->file_read($class->{path}); "package $class->{name};
# 
use common::sense;

sub new {
my \$cls = shift;
bless {		
	\@_,
}, ref \$cls || \$cls;
}

1;";
	
	my ($new) = $file =~ m!^(.*?)(\nsub\b|\n#\@category\b|$)!s;
	
	return 1, $new;
}

# Возвращает номер строки и тело метода
sub method_get {
	my ($self, $method) = @_;
	my $file = $self->file_read($method->{path}); "sub $method->{name} {\n\tmy (\$self) = \@_;\n\n\t\$self\n}\n";
	
	my ($before, $body) = $file =~ /\A(.*^)(sub\s+\Q$method->{name}\E.*^\})/ms;
	
	my $line = 1;
	$line++ while $before =~ /\n/g;
	
	return $line, $body;
}

#@category Писатели

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
	while($text =~ /()$re/go) {
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