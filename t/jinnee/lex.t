use common::sense;
use open qw/:std :utf8/;

use Test::More;

use lib "lib";
use Ninja::Ext::Runtime;

use Jinnee;


my $jinnee = Jinnee->new;

my $A = ["a", "variable"];
my $B = ["b", "variable"];
my $S = [" ", "space"];
my $N = ["\n", "newline"];

subtest methods => sub {

	is_deeply $jinnee->lex("a method"), [$A, $S, ["method", "unary"]];
	
	is_deeply $jinnee->lex("a\nmethod"), [$A, $N, ["method", "unary"]];
	is_deeply $jinnee->lex("a \n method"), [$A, $S, $N, $S, ["method", "unary"]];

	is_deeply $jinnee->lex("method"), [["method", "error"]];

	is_deeply $jinnee->lex("method a"), [["method", "error"], $S, $A];
	
	is_deeply $jinnee->lex("a method b"), [$A, $S, ["method", "method"], $S, $B];
	is_deeply $jinnee->lex("a\nmethod b"), [$A, $N, ["method", "method"], $S, $B];
	is_deeply $jinnee->lex("a\nmethod\nb"), [$A, $N, ["method", "unary"], $N, $B];
	
	is_deeply $jinnee->lex("a method method b"), [$A, $S, ["method", "unary"], $S, ["method", "method"], $S, $B];

	done_testing();
};

subtest operators => sub {

	is_deeply $jinnee->lex("-a"), [["-", "lunary"], $A];
	is_deeply $jinnee->lex("(-a)"), [["(", "staple"], ["-", "lunary"], $A, [")", "staple"]];

	is_deeply $jinnee->lex("a++"), [$A, ["++", "unary"]];
	
	is_deeply $jinnee->lex("a*b"), [$A, ["*", "method"], $B];
	is_deeply $jinnee->lex("a-- * b"), [$A, ["--", "unary"], $S, ["*", "method"], $S, $B];
	is_deeply $jinnee->lex("a - -b"), [$A, $S, ["-", "method"], $S, ["-", "lunary"], $B];

};


done_testing();
