package Jinnee;
# Компиллятор языка Джинни

use common::sense;


sub new {
	my $cls = shift;
	bless {
		INC => ["kernel", "src"],
		packages => {},			# пакет => { INC => "src" }
		classes => {},			# класс => { package => }
		@_
	}, $cls;
}

#@category Компиллятор

# Компилирует метод и вставляет его в файл с классом
sub method_compile {
	my ($self) = @_;
	$self
}


#@category Пакеты

#!!
#A package_list r
#^A inc -> x |map "$x/*" glob ++ "$x/*" glob -> n |if n !~ /\/\.{1,2}\z/ |map n slice 1 + x% |if n ~ /$r/i

# список пакетов соответствующих фильтру
sub package_list {
	my ($self, $re) = @_;
	%{$self->{packages}} = ();
	grep { /$re/i } map { my $x=$_; map { 
		my $package = substr $_, 1+length $x;
		$self->{packages}->{$package} = { INC => $x };
		$package
	} (grep { !/\/\.{1,2}\z/ } <"$_/.*">), <"$_/*"> } @{$self->{INC}}
}

# список классов в указанном пакете
sub class_list {
	my ($self, $re, $package) = @_;
	
	my $path = "$self->{packages}{$package}{INC}/$package";
	
	grep { /$re/i }	map { substr $_, 1+length $path	} (grep { !/\/\.{1,2}\z/ } <"$path/.*">), <"$path/*"> 

}

# список категорий
sub category_list {
	my ($self, $re, $package, $class) = @_;
	
	my $path = "$self->{packages}{$package}{INC}/$package/$class";
	
	grep { /$re/i }	map { substr $_, 1+length $path	} (grep { !/\/\.{1,2}\z/ } <"$path/.*">), <"$path/*">
}

# список методов. $category может быть '*'
sub method_list {
	my ($self, $re, $package, $class, $category) = @_;
	
	my $path = "$self->{packages}{$package}{INC}/$package/$class/$category";
	
	grep { /$re/i }	map { substr $_, 1+length $path	} (grep { !/\/\.{1,2}\z/ } <"$path/.*">), <"$path/*">
}

1;