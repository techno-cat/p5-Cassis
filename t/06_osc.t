use strict;
use Test::More 0.98;
use Math::Trig ':pi';

use_ok $_ for qw(
    Cassis::Osc
);

can_ok 'Cassis::Osc', qw/new exec set_freq freq/;
can_ok 'Cassis::Osc::Sin'  , 'oscillate';
can_ok 'Cassis::Osc::Pulse', 'oscillate';
can_ok 'Cassis::Osc::Saw'  , 'oscillate';
can_ok 'Cassis::Osc::Tri'  , 'oscillate';

{
    my $osc = Cassis::Osc::Sin->new( fs => 44100 );
    is $osc->freq(), 1.0, 'default value of freq.';

    $osc->set_freq( 4.0 );
    is $osc->freq(), 4.0, 'set freq.';
}

{
    my $osc = Cassis::Osc::Sin->new( fs => 4, freq => 1 );
    my $got = $osc->exec( num => 5 );
    is_deeply $got, [ 0.0, sin(pi2 * 0.25), sin(pi2 * 0.5), sin(pi2 * 0.75), 0.0 ], 'Sin.';
}

{
    my $osc = Cassis::Osc::Pulse->new( fs => 4, freq => 1 );
    my $got = $osc->exec( num => 5 );
    is_deeply $got, [ -1, -1, +1, +1, -1 ], 'Pulse.';
}

{
    my $osc = Cassis::Osc::Saw->new( fs => 4, freq => 1 );
    my $got = $osc->exec( num => 5 );
    is_deeply $got, [ -1, (-1 + 0.5), (-1 + 1), (-1 + 1.5), -1 ], 'Saw.';
}

{
    my $osc = Cassis::Osc::Tri->new( fs => 4, freq => 1 );
    my $got = $osc->exec( num => 5 );
    is_deeply $got, [ -1, 0, +1, 0, -1 ], 'Tri.';
}

{
    my $osc = Cassis::Osc::Pulse->new( fs => 2, freq => 1 );
    my $osc2 = Cassis::Osc::Pulse->new( fs => 4, freq => 1 );
    my $got = $osc->exec( num => 8, mod_freq => {
        src => $osc2->exec( num => 8 ),
        depth => 0.0
    } );
    is_deeply $got, [ -1, +1, -1, +1, -1, +1, -1, +1 ], 'with modulation.';
}

{
    my $osc = Cassis::Osc::Pulse->new( fs => 2, freq => 1 );
    my $osc2 = Cassis::Osc::Pulse->new( fs => 4, freq => 1 );
    my $got = $osc->exec( num => 8, mod_freq => {
        src => $osc2->exec( num => 8 ),
        depth => 1.0
    } );
    is_deeply $got, [ -1, -1, -1, -1, -1, -1, -1, -1 ], 'with modulation.';
}

{
    my $osc = Cassis::Osc::Pulse->new( fs => 2, freq => 1 );
    my $osc2 = Cassis::Osc::Pulse->new( fs => 4, freq => 1 );
    my $got = $osc->exec( num => 8, mod_freq => {
        src => $osc2->exec( num => 8 ),
        depth => 0.5
    } );
    is_deeply $got, [ -1, -1, +1, -1, -1, -1, +1, -1 ], 'with modulation.';
}

done_testing;

