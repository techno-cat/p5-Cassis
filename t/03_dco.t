use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis
);

can_ok 'Cassis::Dco', 'new', 'exec', 'set_pitch', 'pitch';
can_ok 'Cassis::Dco::Sin'  , 'oscillate';
can_ok 'Cassis::Dco::Pulse', 'oscillate';
can_ok 'Cassis::Dco::Saw'  , 'oscillate';
can_ok 'Cassis::Dco::Tri'  , 'oscillate';

done_testing;

