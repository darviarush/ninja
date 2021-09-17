use common::sense;
use Test::More;

use lib "lib";
use Ninja::Ext::Runtime;

use Jinnee;


my $jinnee = Jinnee->new;

subtest op => sub {

	::msg $jinnee->to_tree("a - -x + b * c");

	done_testing();
};

done_testing();