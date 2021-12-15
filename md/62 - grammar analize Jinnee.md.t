# Дерево грамматического разбора языка Джинни

	use Ninja::Ext::Runtime;

	use Jinnee;

	my $jinnee = Jinnee->new;


## Операторы

	#$Jinnee::DEBUG = 2;

Бинарные операторы с одинаковым приоритетом выстраиваются в список:

	Jinnee::s_tree0($jinnee->to_tree("a - x + b - c"))  	→ "(a - x + b - c)";
	Jinnee::s_tree0($jinnee->to_tree("a - -x + b * c")) 	→ "(a - (x -) + (b * c))";
	Jinnee::s_tree0($jinnee->to_tree("a - (-x) + b*c")) 	→ "(a - (x -) + (b * c))";
	Jinnee::s_tree0($jinnee->to_tree("a < -b < c+1 = 5")) 	→ "(a < (b -) < (c + 1) = 5)";
	
Cкобки остаются:

	Jinnee::s_tree0($jinnee->to_tree("((a - (r-(-x)+6)) + b)*c")) → "(((a - (r - (x -) + 6)) + b) * c)";


## Сообщения

Сообщения посылаются методам и могут быть унарными и бинарными.

	is Jinnee::s_tree0($jinnee->to_tree("a method++ * -x!")), "(((a method)++) * ((x -)!))";
	is Jinnee::s_tree0($jinnee->to_tree("a method -x!")), "(a method ((x -)!))";
	is Jinnee::s_tree0($jinnee->to_tree("a at i put 10")), "(a at i put 10)";
	
## Методы

	is Jinnee::s_tree0($jinnee->to_tree(<<"END1"))."\n", <<"END2";
	a save
	# method

									
	"x.log" asFile set (
			10.1
		) write "save"


	^a + 1	# this is return

	END1
	((a save)
	(("x.log" asFile) set 10.1 write "save")
	((a + 1) ^))
	END2
