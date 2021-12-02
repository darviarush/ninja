package Ninja::Jinnee::Perl;
# Парсер программ на perl

use common::sense;

use parent 'Ninja::Role::Jinnee';

#@category Парсинг

my $PACKAGE  = qr/^ [\ \t]* \#\@package \s+ (?<package> [\w:]+ )/mxn;
my $CLASS    = qr/^ [\ \t]* package \s+ (?<class> [\w:]+ )/mxn;
my $CATEGORY = qr/^ [\ \t]* \#\@category [\ \t]+ (?<category> .*? ) [\ \t]* $/mxn;
my $METHOD   = qr/^ ([\ \t]* \#.*\n)* [\ \t]* sub \s+ (?<method>[\w:]+) .* ([\ \t]*(\n|$))+ /mx;
my $END      = qr/(?<end> ^ [\ \t]* \} [\ \t]* ([\ \t]*(\n|$))+ )/mxn;

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

sub parse {
	my ($self, $code) = @_;
	
	local $_ = $code;
	
	my @A;
	my $end = 0;
	my $package;
	my $class;
	my $category;
	
	while(m{$PACKAGE|$CLASS|$CATEGORY|$METHOD|$END}gx) {

		my $mid = length $`;
		my $after = $mid + length $&;
		my @a = (from=>$end, mid=>$mid, after=>$after);
		$end = $after;
		
		if(exists $+{package}) {
			push @A, $package = {section=>"packages", name=>$+{package}, @a};
		}
		elsif(exists $+{class}) {
			push @A, $class = {section=>"classes", name=>$+{class}, package=>$package, @a};
		}
		elsif(exists $+{category}) {
			push @A, $category = {section=>"categories", name=>$+{category}, class=>$class, @a};
		}
		elsif(exists $+{method}) {
			push @A, {section=>"methods", name=>$+{method}, category=>$category, @a};
		}
		elsif(exists $+{end}) {
			$A[$#A]{end} = $end if @A;
		}

	}
	
	return @A;
}



1;