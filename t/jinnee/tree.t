use common::sense;
use open qw/:std :utf8/;

use Test::More;

use lib "lib";
use Ninja::Ext::Runtime;

use Jinnee;


my $jinnee = Jinnee->new;

subtest op => sub {

	#$Jinnee::DEBUG = 2;

	# бинарные операторы с одинаковым приоритетом выстраиваются в список

	is Jinnee::s_tree0($jinnee->to_tree("a - -x + b * c")), "(a - (x -) + (b * c))";
	is Jinnee::s_tree0($jinnee->to_tree("a - (-x) + b*c")), "(a - (x -) + (b * c))";
	
	# скобки остаются
	is Jinnee::s_tree0($jinnee->to_tree("((a - (r-(-x)+6)) + b)*c")), "(((a - (r - (x -) + 6)) + b) * c)";

	done_testing();
};


subtest method => sub {

	$Jinnee::DEBUG = 2;
	is Jinnee::s_tree0($jinnee->to_tree("a method++ * -x!")), "(((a method)++) * ((x -)!))";

	# is Jinnee::s_tree0($jinnee->to_tree("a method -x!")), "(a method ((x -)!))";

	# is Jinnee::s_tree0($jinnee->to_tree("a at i put 10")), "(a at i put 10)";
	# is Jinnee::s_tree0($jinnee->to_tree("a < -b < c+1 = 5")), "(a < (b -) < (c + 1) = 5)";

	done_testing();
};


done_testing();