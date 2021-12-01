package Ninja::Jinnee::Perl;
# Парсер программ на perl

use common::sense;

use parent 'Ninja::Role::Jinnee';

#@category Парсинг

my $PACKAGE = qr/\#\@package \s+ (?<package> [\w:]+ )/x;
my $CLASS = qr/\b package \s+ (?<class> [\w:]+ )/mx;
my $CATEGORY = qr/\#\@category [\ \t]+ (?<category> .*? ) [\ \t]* $/mx;
my $METHOD = qr/\b sub \s+ (?<method>[\w:]+)/mx;
my $END = qr/(?<end> ^ \} [\ \t]* $ )/mx;
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
	my $prev;
	my $end = 0;
	my $package = {section=>"packages", name=>"*"};
	my $class = {section=>"classes", name=>"*"};
	my $category = {section=>"categories", name=>"*"};
	
	while(m{$PACKAGE|$CLASS|$CATEGORY|$METHOD|$END}gx) {

		my $mid = length($`) + length $&;
		my @a = (from=>$end, mid=>$mid);
		$end = $mid;
		
		if(exists $+{package}) {
			push @A, $prev = $package = {section=>"packages", name=>$+{package}};
		}
		elsif(exists $+{class}) {
			push @A, $prev = $class = {section=>"classes", name=>$+{class}, package=>$package, @a};
		}
		elsif(exists $+{category}) {
			push @A, $prev = $category = {section=>"categories", name=>$+{category}, class=>$class};
		}
		elsif(exists $+{method}) {
			push @A, $prev = {section=>"methods", name=>$+{method}, category=>$category, @a};
		}
		elsif(exists $+{end}) {
			$prev->{to} = $end if $prev;
		}

	}
	
	return @A;
}



1;