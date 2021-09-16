use common::sense;
use Test::More;

use lib "lib";
use Ninja::Ext::Runtime;

use Jinnee;


my $jinnee = Jinnee->new;

subtest methods => sub {

	is_deeply $jinnee->lex("a method"), [["a", "variable"], [" ", "space"], ["method", "unary"]];
	
	is_deeply $jinnee->lex("a\nmethod"), [["a", "variable"], ["\n", "newline"], ["method", "unary"]];

	is_deeply $jinnee->lex("method"), [["method", "error"]];

	is_deeply $jinnee->lex("method a"), [["method", "error"], [" ", "space"], ["a", "variable"]];
	
	is_deeply $jinnee->lex("a method b"), [["a", "variable"], [" ", "space"], ["method", "method"], [" ", "space"], ["b", "variable"]];

	done_testing();
};

# subtest operators => sub {

	# is_deeply ::msga $jinnee->lex("-a"), [["-", "unary"], ["a", "variable"]];

	# is_deeply ::msga $jinnee->lex("a++"), [["a", "variable"], ["++", "unary"]];

# };


done_testing();
