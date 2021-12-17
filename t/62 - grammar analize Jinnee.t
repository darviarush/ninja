 use common::sense; use open qw/:std :utf8/; use lib "lib"; use Test::More; use Ninja::Ext::Runtime; # Дерево грамматического разбора языка Джинни

use Ninja::Ext::Runtime;

use Jinnee;

my $jinnee = Jinnee->new;
#$Jinnee::DEBUG = 2;

subtest 'Операторы' => sub {

# Бинарные операторы с одинаковым приоритетом выстраиваются в список:

is_deeply(Jinnee::s_tree0($jinnee->to_tree("a - x + b - c")), "(a - x + b - c)", 'Jinnee::s_tree0($jinnee->to_tree("a - x + b - c")) ↦ "(a - x + b - c)"');
is_deeply(Jinnee::s_tree0($jinnee->to_tree("a - -x + b * c")), "(a - (x -) + (b * c))", 'Jinnee::s_tree0($jinnee->to_tree("a - -x + b * c")) ↦ "(a - (x -) + (b * c))"');
is_deeply(Jinnee::s_tree0($jinnee->to_tree("a - (-x) + b*c")), "(a - (x -) + (b * c))", 'Jinnee::s_tree0($jinnee->to_tree("a - (-x) + b*c")) ↦ "(a - (x -) + (b * c))"');
is_deeply(Jinnee::s_tree0($jinnee->to_tree("a < -b < c+1 = 5")), "(a < (b -) < (c + 1) = 5)", 'Jinnee::s_tree0($jinnee->to_tree("a < -b < c+1 = 5")) ↦ "(a < (b -) < (c + 1) = 5)"');

# Cкобки остаются:

is_deeply(Jinnee::s_tree0($jinnee->to_tree("((a - (r-(-x)+6)) + b)*c")), "(((a - (r - (x -) + 6)) + b) * c)", 'Jinnee::s_tree0($jinnee->to_tree("((a - (r-(-x)+6)) + b)*c")) ↦ "(((a - (r - (x -) + 6)) + b) * c)"');


done_testing(); }; subtest 'Сообщения' => sub {

# Сообщения посылаются методам и могут быть унарными и бинарными.

# Сообщения имеют одинаковый приоритет и выстраиваются в список.

is_deeply(Jinnee::s_tree0($jinnee->to_tree("a method++ * -x!")), "(((a method)++) * ((x -)!))", 'Jinnee::s_tree0($jinnee->to_tree("a method++ * -x!")) ↦ "(((a method)++) * ((x -)!))"');
is_deeply(Jinnee::s_tree0($jinnee->to_tree("a method -x!")), "(a method ((x -)!))", 'Jinnee::s_tree0($jinnee->to_tree("a method -x!")) ↦ "(a method ((x -)!))"');
is_deeply(Jinnee::s_tree0($jinnee->to_tree("a at i put 10")), "(a at i put 10)", 'Jinnee::s_tree0($jinnee->to_tree("a at i put 10")) ↦ "(a at i put 10)"');

done_testing(); }; subtest 'Методы' => sub {

is_deeply(Jinnee::s_tree0($jinnee->to_tree(<<"END1"))."\n", <<"END2", 'Jinnee::s_tree0($jinnee->to_tree(<<"END1"))."\\n" ↦ <<"END2"');
a save
# method

								
"x.log" asFile set (
		10.1
	) write "save"


^a + 1	# this is return

END1
((a save)
(("x.log" asFile) set (10.1) write "save")
((a + 1) ^))
END2
done_testing(); }; 
done_testing();
