use utf8;
use Tcl;





$i = Tcl->new;


$i->SetVar("argv", Tcl::GLOBAL_ONLY);
$i->SetVar("tcl_interactive", 0, Tcl::GLOBAL_ONLY);
$i->Init;

# unless (pkg_require($i, 'Tk', $i->GetVar('tcl_version'))) {
	# warn $@; # in case of failure: warn to show this error for user
	# unless (pkg_require($i, 'Tk')) { # try w/o version
		# die $@; # ...and then re-die to have this error for user
	# }
# }

$i->EvalFile("ex.tcl");

# $i->Eval(q{
# pack [text .t -wrap word] -fill both -expand 1

# .t insert end "Здравствуй Мир!"

# tk appname "Мировой!"

# });

while($wid = eval { $i->invoke(qw/ winfo id . /) }) {
	warn "wid: ", $wid, " k: ", $k++;
	$i->DoOneEvent(0);
}
