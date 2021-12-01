package Ninja::Role::Jinnee;
# Базовый класс для языка

use common::sense;

use Ninja::Ext::File qw/f/;


sub new {
	my $cls = shift;
	bless {		
		@_,
	}, ref $cls || $cls;
}

#@category Синтаксис

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