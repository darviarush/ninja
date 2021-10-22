$\ = "\n"; $, = ", ";

package A {
	sub fn { 10 }
	$x = 20;
}

use DDP; p %main::;

{
	local %main::A::;
	#local @A::{keys %A::};
	
	*A::fn = sub {6};
	$A::x = 3;
	
	print &A::fn;
	print $A::x;	
}

print &A::fn;
print $A::x;

