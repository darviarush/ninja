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

my %MANY = qw/package packages class classes category categories method methods/;

#my $LITERAL = 

sub parse {
	my ($self, $file) = @_;
	
	local $_ = $file->read;
	
	my %x;
	$x{package} = {section=>"packages", name=>$file->dir // "[*]"};
	$x{} = 
	
	my $end = 0;
	my @A;
	my $package;
	my $class;
	my $category;
	
	while($file =~ m{$PACKAGE|$CLASS|$CATEGORY|$METHOD|$END}gx) {
		
		$end = length($`) + length $&, next if exists $+{end};
		
		
		my @args = (from => $end, mid => length($`), len => length($&), );
		
		if(exists $+{package}) {
			push @A, {section=>"packages", name=>$+{package}};
		}
		elsif(exists $+{class}) {
			push @A, {section=>"classes", name=>$+{class}, package=>$package};
		}
		elsif(exists $+{category}) {
			push @A, {section=>"categories", name=>$+{category}, class=>$class};
		}
		elsif(exists $+{method}) {
			push @A, {section=>"methods", name=>$+{method}, category=>$category};
		}
				
	}
	
	return @A;
}

1;