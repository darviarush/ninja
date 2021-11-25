package Ninja::Role::Jinnee;
# Базовый класс для языка

use common::sense;

sub new {
	my $cls = shift;
	bless {		
		@_,
	}, ref $cls || $cls;
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
		
		
		if(/^\s*key\s+([a-z_]\w*)\s+/i) {
			
		}
		else {
			die "Строка $. файла `$path` не распознана!";
		}
	}
	
	close $f;
	
	$self
}


1;