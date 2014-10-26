use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis
);

use_ok $_ for qw(
    Cassis
);

can_ok 'Cassis::Dca', 'new', 'exec', 'set_volume', 'volume';

my $dca = Cassis::Dca->new();

is $dca->volume(), 1.0;

$dca->set_volume( 2.0 );
is $dca->volume(), 2.0;

is_deeply $dca->exec( src => [ 1, 2, 3 ] ), [ 2, 4, 6 ];

$dca->set_volume( 1.0 );
is_deeply $dca->exec(
    src => [ 1, 2, 3 ],
    mod_volume => {
        src => [ -1, 0, +1 ], depth => 1.0
    }
), [ 0, 1, 3 ]; #[ 1 * (0.5 + (-1 * 0.5)), 2 * (0.5 + (0 * 0.5)), 3 * (0.5 + (+1 * 0.5)) ];

done_testing;

