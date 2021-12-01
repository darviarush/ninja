package Ninja::Jinnee::Text;
# Парсер неизвестных файлов. Просто подсвечивает классы символов

use common::sense;

use parent 'Ninja::Role::Jinnee';

sub parse {
	my ($self, $code) = @_;

	return;
}

sub color {
	my ($self, $code) = @_;
	
	return [[$code]];
}

1;