 use common::sense; use open qw/:std :utf8/; use lib "lib"; use Test::More; use Ninja::Ext::Runtime; # Мониторы и гении

use Ninja::Monitor::Sector;
use Ninja::Ext::File qw/f/;

subtest 'Ninja::Jinnee::Perl' => sub {

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

is_deeply(($x), ($y), '$x ↦ $y');

is_deeply((substr $code, $x->{"[§]"}{A}{""}{from}, $x->{"[§]"}{A}{""}{end}), ("\npackage A;\n\n"), 'substr $code, $x->{"[§]"}{A}{""}{from}, $x->{"[§]"}{A}{""}{end} ↦ "\\npackage A;\\n\\n"');
is_deeply((substr $code, $x->{"[§]"}{A}{"[§]"}{"[¶]"}{from}, $x->{"[§]"}{A}{"[§]"}{"[¶]"}{end}), ("1;"), 'substr $code, $x->{"[§]"}{A}{"[§]"}{"[¶]"}{from}, $x->{"[§]"}{A}{"[§]"}{"[¶]"}{end} ↦ "1;"');done_testing(); }; 
done_testing();
