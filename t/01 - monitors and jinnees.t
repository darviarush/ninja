 use common::sense; use open qw/:std :utf8/; use lib "lib"; use Test::More; use Ninja::Ext::Runtime; # Мониторы и гении

use Ninja::Monitor::Sector;

subtest 'Perl' => sub {

use Ninja::Jinnee::Perl;

my $perl = Ninja::Jinnee::Perl->new;

is_deeply(10, 10, '10 ↦ 10');
done_testing(); }; 
done_testing();
