package Ninja::Ext::Color;
# колоризирует синтаксис

use common::sense;

use Syntax::Highlight::Engine::Kate;

# конструктор
sub new {
	my $cls = shift;
	bless {}, ref $cls || $cls;
}

# список поддерживаемых языков
sub list {
	my ($self) = @_;
	Syntax::Highlight::Engine::Kate->new->languageList
}

# список поддерживаемых секций
sub menu {
	my ($self) = @_;
	Syntax::Highlight::Engine::Kate->new->sections
}

# возвращает список расширений
sub extlist {
	my ($self) = @_;
	Syntax::Highlight::Engine::Kate->new->extensions
}

# определяет язык по пути
sub by {
	my ($self, $path) = @_;
	Syntax::Highlight::Engine::Kate->new->languagePropose($path)
}

# определяет название плагина по пути
sub plugin {
	my ($self, $lang) = @_;
	"Syntax::Highlight::Engine::Kate::" . Syntax::Highlight::Engine::Kate->new->languagePlug($lang, 1)
}

# подгружает плагин
sub load {
	my ($self, $lang) = @_;
	my $path = $self->plugin($lang);
	$path =~ s!::!/!g;
	require "$path.pm";
	$lang
}

# возвращает объект языка
sub syntax {
	my ($self, $lang) = @_;
	$self->{syntax}{$lang} //= Syntax::Highlight::Engine::Kate->new(
        language => $self->load($lang),
	)
}

# колоризирует язык
sub color {
	my ($self, $lang, $text) = @_;
	my $syntax = $self->syntax($lang);
	
	
	my @res = $syntax->highlight($text);
	
	my $out = [];
	while(@res) {
		my $x = shift @res;
		my $f = shift @res;
		push @$out, [$x, $f];
	}
	
	$out
}

1;
