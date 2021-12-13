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


# {пакет1=>{класс1=>{""=>{from,end}, категория1=>{""=>порядок категории, метод1=>{from, end, order=>порядок метода}}}}}

sub parse {
	my ($self, $code) = @_;
	
	local $_ = $code;
	
	my $x = {};
	
	# части адреса
	my $package = "[§]";
	my $class = "[§]";
	my $category = "[§]";

	my $from = 0;
	
	my @A;	# текущий
	
	
	while(m{$CLASS|$CATEGORY|$METHOD|$END}gx) {

		my $mid = length $`;
		my $after = $mid + length $&;
		
		if(exists $+{package}) {
			$A[$#A]{end} = $mid if @A;
			
			push @A, $x->{$package}{$class = $+{class}}{""} = {
				from => $mid, 
				end => $after,
			};
			# сбрасываем по дефолту
			$class = "[§]";
			$category = "[§]";
		}
		elsif(exists $+{class}) {
			# продолжается до категории или комментариев плотно прилегающих к первому методу
			push @A, $x->{$package}{$class = $+{class}}{""} = {
				from => $end,
				end => $after,
			};
			# сбрасываем в дефолтную
			$category = "[§]";
		}
		elsif(exists $+{category}) {
			# продолжается от себя - передаём from - на end предыдущему
			$A[$#A]{end} = $mid if @A;
			
			push @A, $x->{$package}{$class}{$category = $+{category}}{""} = {from=>$mid, end=>$after};
		}
		elsif(exists $+{method}) {
			# если перед ним класс - то отдаём классу текст до комментариев перед методом
			if($category eq "[§]") {
				$from = length $` if /^(#.*\n)*\Q$&\E/;
				$A[$#A]{end} = $from if @A;
			}
			push @A, $x->{$package}{$class}{$category}{$+{method}} = {
				from => $from,
				end => $after,
			};
		}
		elsif(exists $+{end}) {
			$A[$#A]{end} = $after if @A;
		}

		$from = $after;
	}
	
	if($A[$#A]{end} != length $code) {
		$x->{$package}{$class}{"[¶]"}{"[¶]"} = {from=>$A[$#A]{end}, end => length $code, order => $order+1};
	}
	
	my $i = 0;
	$_->{order} = ++$i for @A;
	
	return $x;
}

1;