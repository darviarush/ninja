use common::sense;
use open qw/:std :utf8/;

sub _translate {
	my ($s) = @_;
	my %S = qw/
	а a б b в v г g д d е e ё oh ж jh з z и i й j к k л l м m н n о o п p р r с s т t 
	у u ф f х hh ц c ч ch ш sh щ csh ъ qh ы y ь q э eh ю uh я ah
	А A Б B В V Г G Д D Е E Ё OH Ж JH З Z И I Й J К K Л L М M Н N О O П P Р R С S Т T 
	У U Ф F Х HH Ц C Ч CH Ш SH Щ CSH Ъ QH Ы Y Ь Q Э EH Ю UH Я AH
	/;
	$s =~ s{ [абвгдежзийклмнопрстуфхцчшщъыьэюяё] }{	$S{$&} }gixe;
	
	$s =~ s/\W/_/g;
	$s
}


print _translate("Файл, Ёлки, въбить! Щётка, ёж!");