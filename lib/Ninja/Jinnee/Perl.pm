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
	
	my @A = {};
	
	
	while(m{$CLASS|$CATEGORY|$METHOD|$END}gx) {

		my $mid = length $`;
		my $after = $mid + length $&;
		
		if(exists $+{class}) {
			push @A, $x->{$package}{$class = $+{class}}{""} = {from=>$from, end=>$after};
			$category = "[§]";
		}
		elsif(exists $+{category}) {
			$A[$#A]{end} = $mid;
			push @A, $x->{$package}{$class}{$category = $+{category}}{""} = {from=>$mid, end=>$after};
		}
		elsif(exists $+{method}) {
			# если перед ним класс - то отдаём классу текст до комментариев перед методом
			if(1 >= keys %{$x->{$package}{$class}}) {
				$from = length $` if /^(#.*\n)*\Q$&\E/;
				$A[$#A]{end} = $from;
			}
			push @A, $x->{$package}{$class}{$category}{$+{method}} = {from=>$from, end=>$after};
		}
		elsif(exists $+{end}) {
			$A[$#A]{end} = $after;
		}

		$from = $after;
	}
	
	if($A[$#A]{end} != length $code) {
		$x->{$package}{$class}{"[§]"}{"[¶]"} = {from=>$A[$#A]{end}, end=>length $code};
	}

	return $x;
}

1;