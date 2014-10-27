use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis::DCO
);

can_ok 'Cassis::DCO', qw/new exec set_pitch pitch/;
can_ok 'Cassis::DCO::Sin'  , 'oscillate';
can_ok 'Cassis::DCO::Pulse', 'oscillate';
can_ok 'Cassis::DCO::Saw'  , 'oscillate';
can_ok 'Cassis::DCO::Tri'  , 'oscillate';

done_testing;

