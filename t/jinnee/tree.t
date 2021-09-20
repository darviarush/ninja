use common::sense;
use open qw/:std :utf8/;

use Test::More;

use lib "lib";
use Ninja::Ext::Runtime;

use Jinnee;


my $jinnee = Jinnee->new;

subtest op => sub {

	is Jinnee::s_tree0($jinnee->to_tree("a - -x + b * c")), "((a - (x -)) + (b * c))";
	is Jinnee::s_tree0($jinnee->to_tree("a - (-x) + b*c")), "((a - (x -)) + (b * c))";
	is Jinnee::s_tree0($jinnee->to_tree("((a - (r-(-x)+6)) + b)*c")), "(((a - ((r - (x -)) + 6)) + b) * c)";

	done_testing();
};


subtest method => sub {

	is Jinnee::s_tree0($jinnee->to_tree("a method++ * -x!")), "(((a method)++) * ((x -)!))";
	
	$Jinnee::DEBUG = 2;
	is Jinnee::s_tree0($jinnee->to_tree("a method -x!")), "(a method ((x -)!))";

	done_testing();
};


done_testing();