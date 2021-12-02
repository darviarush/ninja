package Ninja::Role::Monitor;
# Монитор файловой системы

use common::sense;

use Ninja::Ext::File qw/f/;


# конструктор
sub new {
	my $cls = shift;
	bless {
		INC => ["."],
		jinnee => {},
		@_
	}, ref $cls || $cls;
}

#@category Гении

# возвращает гения по расширению файла или первой строке
sub jinnee {
	my ($self, $file) = @_;
	
	my $path = $file->path;
	my $lang = "Text";
	
	if($path =~ /\.(pl|pm|t)$/) {
		$lang = "Perl";
	}
	
	$self->{jinnee}{$lang} //= do {
		require "Ninja/Jinnee/$lang.pm";
		"Ninja::Jinnee::$lang"->new
	}
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
	my $path = $who->{section} eq "classes"? $who->{path}: $who->{category}{class}{path};
	my $file = f $path;
	
	$self->jinnee($file)->color($who, $text)
}

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

# # возвращает множество в INC - список пакетов и список модулей в пакете [-]
# sub package_list_info {
	# my ($self) = @_;

	# my @files;
	# my @packages;
	# my %package;
	# my @nouname;
	
	# for my $inc (@{$self->{INC}}) {
		# for($self->ls($inc)) {
			# my $name = substr $_, 1+length $inc;
			# my $package = +{ section => "packages", inc => $inc, path => $_, name => $name };
			# if(-d $_) {
				# push @packages, $package;
				# $package{$name} = 1;
			# } else {
				# $package->{name} =~ s!\.pm$!!;
				# push @files, $package;
			# }
		# }
	# }

	# # Модули, что не имеют своих каталогов будут входить в пакет [-]
	# for(@files) {
		# if(exists $package{$_->{name}}) { push @packages, $_; }
		# else { push @nouname, $_; }
	# }
	
	# return +{
		# packages => [@nouname? {section => "packages", name => "[-]", nouname => 1}: (), sort { $a->{name} cmp $b->{name} } @packages],
		# nouname => [sort { $a->{name} cmp $b->{name} } @nouname],
	# }
# }

1;
