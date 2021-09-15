use common::sense;
use Test::More;

use lib "lib";
use Ninja::Ext::Runtime;

use Jinnee;


my $jinnee = Jinnee->new;

::p $jinnee->lex("method");

is_deeply $jinnee->lex("a method"), [["a", "variable"], [" ", "space"], ["method", "unary"]];

is_deeply $jinnee->lex("method"), [["method", "error"]];

is_deeply $jinnee->lex("method a"), [["method", "error"], ["a", "variable"]];


done_testing();
