use utf8;
use Tk;
use Tk::Text;


#use open qw/:std :utf8/;


$x = MainWindow->new(-title => "X");

# $text = $x->Scrolled("Text", -scrollbars=>"osoe",
		# -wrap => "word",
	# );
# $text->Subwidget("yscrollbar")->configure(-width=>10);
# $text->Subwidget("xscrollbar")->configure(-width=>10);

$text = $x->Text;

$text->pack;


$text->insert("end", "Всем привет!");


MainLoop;