use utf8;
use Tk;
use Tk::Text;

$Tk::Encoding = "utf-8";

$x = MainWindow->new;

$t = $x->Text;
$t->insert("end", "Привет Мир!");

$t->pack;

MainLoop;
