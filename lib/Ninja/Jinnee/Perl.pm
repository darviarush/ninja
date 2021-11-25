package Ninja::Jinnee::Perl;
# 

use common::sense;

use parent Ninja::Role::Jinnee;

# конструктор
sub new {
	my ($cls) = @_;
	bless {}, ref $cls || $cls;
}

#@category Парсинг

my $PACKAGE = qr/\#@package \s+ (?<package> [\w:]+ )/x;
my $CLASS = qr/\b package \s+ (?<class> [\w:]+ )/mx;
my $CATEGORY = qr/\#@category [\ \t]+ (?<category> .*? ) [\ \t]* $/mx;
my $METHOD = qr/\b sub \s+ (?<method>[\w:]+)/mx;
my $END = qr/(?<end> ^ \} [\ \t]* $/mx;
my $INC = qr/(?<inc> \{ /mx;
my $DEC = qr/(?<dec> \} /mx;
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

#my $LITERAL = 

sub parse {
	my ($self, $file) = @_;
	
	local $_ = $file->read;
	
	my $end = 0;
	my @A; my @S; my $c;
	my $package = {section=>"packages", name=>"*"};
	my $class = {section=>"classes", name=>"*"};
	my $category = {section=>"categories", name=>"*"};
	
	while($file =~ m{$PACKAGE|$CLASS|$CATEGORY|$METHOD|$END|$NOOP|$INC|$DEC}gx) {
		next if exists $+{noop};
		
		if(exists $+{inc}) { $c++ }
		elsif(exists $+{dec}) {
			if($c != 0) $c--;
			if($c == 0 && @S) {
				my $c = pop @S;
				
			}
		}
		
		my $mid = length($`) + length $&;
		my @a = (from=>$end, mid=>$mid);
		$end = $mid;
		
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

	}
	
	return @A;
}



1;