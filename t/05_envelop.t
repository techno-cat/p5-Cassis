use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis::EG
);

can_ok 'Cassis::EG', qw/new set_curve curve set_adsr adsr exec one_shot/;

{
    my $envelop = Cassis::EG->new( fs => 1 );

    is $envelop->curve(), 1.0, 'default value of curve.';
    is_deeply $envelop->adsr(), [ 0, 0, 1, 0], 'default value of adsr.';

    $envelop->set_curve( 2.0 );
    is $envelop->curve(), 2.0, 'set curve.';

    $envelop->set_adsr( [ 4, 2, 0.5, 4 ] );
    is_deeply $envelop->adsr(), [ 4, 2, 0.5, 4 ], 'set adsr.';

    is $envelop->hold(), 0, 'hold before on.';
    is_deeply $envelop->exec( num => 4 ), [ 0, 0, 0, 0 ], 'exec before on.';

    $envelop->set_curve( 1.0 );

    $envelop->trigger( gatetime => 10 );
    is $envelop->hold(), 1, 'in gatetime.';
    is_deeply $envelop->exec( num => 4 ), [ 0.0, 0.25, 0.5, 0.75 ], 'in attack.';
    is_deeply $envelop->exec( num => 2 ), [ 1.0, 0.75 ], 'in decay.';
    is_deeply $envelop->exec( num => 4 ), [ 0.5, 0.5, 0.5, 0.5 ], 'in hold.';
    is $envelop->hold(), 0, 'out of gatetime.';
    is_deeply $envelop->exec( num => 5 ), [ 0.5, 0.375, 0.25, 0.125, 0.0 ], 'in release.';
    is_deeply $envelop->exec( num => 2 ), [ 0.0, 0.0 ], 'out of duration.';
}

{
    my $fs = 2;
    my $envelop = Cassis::EG->new(
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
    is_deeply $envelop->one_shot( gatetime => 10/$fs ), $exp, 'one shot.';
}

{
    my $envelop = Cassis::EG->new(
        fs => 1,
        curve => 1.0,
        adsr => [ 2, 4, 0.0, 3 ]
    );

    $envelop->trigger( gatetime => 4 );
    is_deeply $envelop->exec( num => 2 ), [ 0.0, 0.5 ], 'in attack.';
    is_deeply $envelop->exec( num => 2 ), [ 1.0, 0.75 ], 'in decay.';
    is_deeply $envelop->exec( num => 4 ), [ 0.75, 0.5, 0.25, 0.0 ], 'note off in decay.';
}

done_testing;

