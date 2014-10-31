use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis::EG
);

can_ok 'Cassis::EG', qw/new set_curve curve set_adsr adsr exec one_shot/;

{
    my $envelope = Cassis::EG->new( fs => 1 );

    is $envelope->curve(), 1.0 / exp(1.0), 'default value of curve.';
    is_deeply $envelope->adsr(), [ 0, 0, 1, 0], 'default value of adsr.';

    $envelope->set_curve( 2.0 );
    is $envelope->curve(), 2.0, 'set curve.';

    $envelope->set_adsr( [ 4, 2, 0.5, 4 ] );
    is_deeply $envelope->adsr(), [ 4, 2, 0.5, 4 ], 'set adsr.';

    is $envelope->hold(), 0, 'hold before on.';
    is_deeply $envelope->exec( num => 4 ), [ 0, 0, 0, 0 ], 'exec before on.';

    $envelope->set_curve( 1.0 );

    $envelope->trigger( gatetime => 10 );
    is $envelope->hold(), 1, 'in gatetime.';
    is_deeply $envelope->exec( num => 4 ), [ 0.0, 0.25, 0.5, 0.75 ], 'in attack.';
    is_deeply $envelope->exec( num => 2 ), [ 1.0, 0.75 ], 'in decay.';
    is_deeply $envelope->exec( num => 4 ), [ 0.5, 0.5, 0.5, 0.5 ], 'in hold.';
    is $envelope->hold(), 0, 'out of gatetime.';
    is_deeply $envelope->exec( num => 5 ), [ 0.5, 0.375, 0.25, 0.125, 0.0 ], 'in release.';
    is_deeply $envelope->exec( num => 2 ), [ 0.0, 0.0 ], 'out of duration.';
}

{
    my $fs = 2;
    my $envelope = Cassis::EG->new(
        fs => $fs,
        curve => 1.0,
        adsr => [ 4/$fs, 2/$fs, 0.5, 4/$fs ]
    );

    my $exp = [
        0.0, 0.25, 0.5, 0.75,
        1.0, 0.75,
        0.5, 0.5, 0.5, 0.5,
        0.5, 0.375, 0.25, 0.125, 0.0
    ];
    is_deeply $envelope->one_shot( gatetime => 10/$fs ), $exp, 'one shot.';
}

{
    my $envelope = Cassis::EG->new(
        fs => 1,
        curve => 1.0,
        adsr => [ 2, 4, 0.0, 3 ]
    );

    $envelope->trigger( gatetime => 4 );
    is_deeply $envelope->exec( num => 2 ), [ 0.0, 0.5 ], 'in attack.';
    is_deeply $envelope->exec( num => 2 ), [ 1.0, 0.75 ], 'in decay.';
    is_deeply $envelope->exec( num => 4 ), [ 0.75, 0.5, 0.25, 0.0 ], 'note off in decay.';
}

done_testing;

