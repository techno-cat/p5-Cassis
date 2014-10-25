use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis
);

{
    my $c = Cassis->new();
    is scalar(@{$c->samples()}), 0;

    $c->append( [1,2,3] );
    is_deeply( $c->samples(), [1,2,3] );
}

{
    my $c = Cassis->new( samples => [1,2,3] );
    is_deeply( $c->samples(), [1,2,3] );
    $c->append( [4,5,6] );
    is_deeply( $c->samples(), [1,2,3,4,5,6] );
}

{
    my $c = Cassis->new();
    is $c->{sf}, $Cassis::SAMPLING_RATE;
    is $c->{bits}, $Cassis::BIT_DEPTH;
}

{
    local $Cassis::SAMPLING_RATE = 22050;
    local $Cassis::BIT_DEPTH = 8;

    my $c = Cassis->new();
    is $c->{sf}, 22050;
    is $c->{bits}, 8;
}

done_testing;

