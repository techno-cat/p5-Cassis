use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis::Amp
);

can_ok 'Cassis::Amp', qw/new exec set_volume volume/;

my $amp = Cassis::Amp->new();

is $amp->volume(), 1.0;

$amp->set_volume( 2.0 );
is $amp->volume(), 2.0;

is_deeply $amp->exec( src => [ 1, 2, 3 ] ), [ 2, 4, 6 ];

$amp->set_volume( 1.0 );
is_deeply $amp->exec(
    src => [ 2, 2, 2 ],
    mod_volume => {
        src => [ -1, 0, 1 ], depth => 1.0
    }
), [ 0, 0, 2 ];

is_deeply $amp->exec(
    src => [ 2, 2, 2 ],
    mod_volume => {
        src => [ -1, 0, 1 ], depth => 0.5
    }
), [ 0, 1, 2 ];

is_deeply $amp->exec(
    src => [ 2, 2, 2 ],
    mod_volume => {
        src => [ -1, 0, 1 ], depth => 0.25
    }
), [ 1, 1.5, 2 ];

done_testing;

