use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis::Mixer
);

is_deeply Cassis::Mixer::mix(
    { src => [ 1, 2, 3 ], volume => 0.5 }
), [ 0.5, 1.0, 1.5 ], 'as amplifier.';

is_deeply Cassis::Mixer::mix(
    { src => [ 1, 2, 3 ], volume => 0.5 },
    { src => [ 3, 4, 5 ], volume => 0.5 }
), [ 2, 3, 4 ], 'mixing.';

done_testing;

