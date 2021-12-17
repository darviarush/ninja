# Мониторы и гении

	use Ninja::Monitor::Sector;
	use Ninja::Ext::File qw/f/;

## Ninja::Jinnee::Perl

	use Ninja::Jinnee::Perl;
	
	my $perl = Ninja::Jinnee::Perl->new(f "...ex.pm");
	my $x; my $y;
	
	$x = $perl->parse(my $code = '
	package A;
	
	#@category X
	sub bay {}
	sub pi {}
	1;');

	$y = {
		'[§]' => {
			A => {
				"" => {from=>0, end=>13},
				X => {
					"" => {from=>13, end=>26},
					"bay" => {from=>26, end=>37},
					"pi" => {from=>37, end=>47},
				},
				"[§]" => {
					"[¶]" => {from=>47, end=>49},
				},
			},
		},
	};

	$x → $y;

	substr $code, $x->{"[§]"}{A}{""}{from}, $x->{"[§]"}{A}{""}{end}		→ "\npackage A;\n\n";
	substr $code, $x->{"[§]"}{A}{"[§]"}{"[¶]"}{from}, $x->{"[§]"}{A}{"[§]"}{"[¶]"}{end}		→ "1;";
	
## Ninja::Monitor::Sector

Сектор это монитор .

	my $sector = Ninja::Monitor::Sector->new(INC => ['share/data-for-tests/prj']);
	$sector->;
