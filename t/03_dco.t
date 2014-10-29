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

{
    my $osc = Cassis::DCO::Sin->new( fs => 44100 );
    is $osc->pitch(), 4.0, 'default value of pitch.';
    is $osc->freq(), 440.0, 'get freq.';

    $osc->set_pitch( 5.0 );
    is $osc->pitch(), 5.0, 'set pitch.';
    is $osc->freq(), 880.0, 'get freq.';
}

{
    my $osc = Cassis::DCO::Sin->new( fs => 44100, pitch => 2.0 );
    is $osc->pitch(), 2.0, 'init whit pitch.';
    is $osc->freq(), 110.0, 'get freq.';
}

{
    my $osc = Cassis::DCO::Sin->new( fs => 44100, freq => 220.0 );
    is $osc->pitch(), 3.0, 'init whit freq.';
    is $osc->freq(), 220.0, 'get freq.';

    $osc->set_freq( 440.0 );
    is $osc->pitch(), 4.0, 'set freq.';
    is $osc->freq(), 440.0, 'get freq.';
}

done_testing;
