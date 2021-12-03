package Ninja::Jinnee::Perl;
# Парсер программ на perl

use common::sense;

use parent 'Ninja::Role::Jinnee';

#@category Парсинг

my $PACKAGE  = qr/^ \#\@package \s+ (?<package> [\w:]+ ) [\ \t]* (\n|$)/mxn;
my $CLASS    = qr/^ package \s+ (?<class> [\w:]+ )/mxn;
my $CATEGORY = qr/^ \#\@category [\ \t]+ (?<category> .*? ) [\ \t]* (\n|$)/mxn;
my $METHOD   = qr/^ sub \s+ (?<method>[\w:]+) .* ([\ \t]*(\n|$))+ /mx;
my $END      = qr/(?<end> ^ \} [\ \t]* ([\ \t]*(\n|$))+ )/mxn;

my $INC = qr/(?<inc> \{ )/mx;
my $DEC = qr/(?<dec> \} )/mx;


my $NOOP = qr{ (?<noop>
	"( \\\\ | \\" | [^"] )*"
	| '( \\\\ | \\' | [^'] )*'
	| \# [^\n]*
	| ^=[a-zA-Z] .* ^=cut \b
	| \b __(DATA|END)__ \b .*
	| \b (m|y|tr|qx|qr|qq|q) 
		(?<sym> [^\w\s]) ( \\\\ | \\ \k<sym> | . )*? \k<sym>
) }xms;

my %MANY = qw/package packages class classes category categories method methods/;


# Протокол:
# 	package1
#	class1
#	category1
#	method1
#	
#	1. Если нет пакета в начале файла, то он добавляется
#	2. В конце метода 

# {пакет1=>{класс1=>{категория1=>{""=>порядок категории, метод1=>порядок метода}}}}

sub parse {
	my ($self, $code) = @_;
	
	local $_ = $code;
	
	
	
	my @A;
	my $package = {section=>"packages", name => "."};
	my $class = {section=>"classes", name=> "main"};
	my $category;
	my $end = 0;
	
	
	while(m{$CLASS|$CATEGORY|$METHOD|$END}gx) {

		my $mid = length $`;
		my $after = $mid + length $&;
		my @a = (from=>$end, end=>$after);
		$end = $after;
		
		if(exists $+{class}) {
			# продолжается до категории или комментариев плотно прилегающих к первому методу
			push @A, $class = {section=>"classes", name=>$+{class}, package=>$package, @a};
		}
		elsif(exists $+{category}) {
			# продолжается от себя - передаём from - на end предыдущему
			$A[$#A]{end} = $mid;
			push @A, $category = {section=>"categories", name=>$+{category}, class=>$class, from=>$mid, end=>$after};
		}
		elsif(exists $+{method}) {
			# если перед ним класс - то создаём категорию перед комментариями метода
			if($A[$#A]{section} eq "classes") {
				$mid = length $` if /^(#.*\n)*\Q$&\E/;
				$A[$#A]{end} = $mid;
				@a = (from=>$mid, end=>$after);
				push @A, $category = {section=>"categories", name=>"[§]", category=>$category, from=>$mid, end=>$mid};
			}
			push @A, {section=>"methods", name=>$+{method}, category=>$category, @a};
		}
		elsif(exists $+{end}) {
			$A[$#A]{end} = $end;
		}

	}
	
	if($A[$#A]{end} != length $code) {
		push @A, $category = {section=>"categories", name=>"[¶]", category=>$category, from=>$A[$#A]{end}, end=>$A[$#A]{end}};
		push @A, {section=>"methods", name=>"[¶]", category=>$category, from=>$A[$#A]{end}, end => length $code};
	}
	
	return @A;
}

1;