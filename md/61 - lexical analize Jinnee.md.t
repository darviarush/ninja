# Лексический анализ языка Джинни

	use Jinnee;

	my $who = {};
	my $jinnee = Jinnee->new;

	my $A = ["a", "variable"];
	my $B = ["b", "variable"];
	my $S = [" ", "space"];
	my $N = ["\n", "newline"];

## Методы

	$jinnee->color($who, "a method") 	→ 	[$A, $S, ["method", "unary"]];
	
	is_deeply $jinnee->color($who, "a\nmethod"), [$A, $N, ["method", "unary"]];
	is_deeply $jinnee->color($who, "a \n method"), [$A, $S, $N, $S, ["method", "unary"]];

	is_deeply $jinnee->color($who, "method"), [["method", "error"]];

	is_deeply $jinnee->color($who, "method a"), [["method", "error"], $S, $A];
	
	is_deeply $jinnee->color($who, "a method b"), [$A, $S, ["method", "method"], $S, $B];
	is_deeply $jinnee->color($who, "a\nmethod b"), [$A, $N, ["method", "method"], $S, $B];
	is_deeply $jinnee->color($who, "a\nmethod\nb"), [$A, $N, ["method", "unary"], $N, $B];
	
	is_deeply $jinnee->color($who, "a method method b"), [$A, $S, ["method", "unary"], $S, ["method", "method"], $S, $B];

## Операторы

	is_deeply $jinnee->color($who, "-a"), [["-", "lunary"], $A];
	is_deeply $jinnee->color($who, "(-a)"), [["(", "staple"], ["-", "lunary"], $A, [")", "staple"]];

	is_deeply $jinnee->color($who, "a++"), [$A, ["++", "unary"]];
	
	is_deeply $jinnee->color($who, "a*b"), [$A, ["*", "method"], $B];
	is_deeply $jinnee->color($who, "a-- * b"), [$A, ["--", "unary"], $S, ["*", "method"], $S, $B];
	is_deeply $jinnee->color($who, "a - -b"), [$A, $S, ["-", "method"], $S, ["-", "lunary"], $B];

## Числа

	$jinnee->color($who, "10.1")	→ [[10.1, "number"]];
	$jinnee->color($who, "10")		→ [[10, "integer"]];