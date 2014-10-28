use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis::Noise
);

can_ok 'Cassis::Noise', qw/new exec set_speed speed/;

{
    my $noise = Cassis::Noise->new();
    is $noise->speed(), 1.0, 'default value of speed.';

    $noise->set_speed( 0.5 );
    is $noise->speed(), 0.5, 'set speed.';
}

{
    local $Cassis::Noise::NOISE_FUNC = sub {
        [ 1, 2, 3, 4, 5 ];
    };

    my $noise = Cassis::Noise->new();
    my $got = $noise->exec( num => 5 );
    is_deeply $got, [ 1, 2, 3, 4, 5 ], 'exec.';
}

{
    my $noise = Cassis::Noise->new( noise => [ 1, 2, 3, 4, 5 ] );
    my $got = $noise->exec( num => 5 );
    is_deeply $got, [ 1, 2, 3, 4, 5 ], 'exec.';
}

{
    my $noise = Cassis::Noise->new(
        speed => 0.5, noise => [ 1, 2, 3, 4, 5 ] );
    my $got = $noise->exec( num => 5 );
    is_deeply $got, [ 1, 1, 2, 2, 3 ], 'exec.';
}

{
    my $noise = Cassis::Noise->new( noise => [ 1, 2, 3, 4, 5 ] );
    my $got = $noise->exec(
        num => 5,
        mod_speed => {
            src => [ 1, 1, 0, 0, 1 ],
            depth => 1.0
        }
    );
    is_deeply $got, [ 1, 2, 3, 3, 3 ], 'with modulation.';
}

done_testing;

