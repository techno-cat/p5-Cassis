use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Cassis::Iir2
);

can_ok 'Cassis::Iir2', qw/new exec params set_cutoff cutoff set_q q/;

my @src = map { 64 < ($_ % 128) ? -1.0 : 1.0; } 0..511;

my $cutoff = 0.05;
my $q = 1.0 / sqrt(2.0);
{
    my $expected = Cassis::Iir2::LPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src
    );
    my $got = Cassis::Iir2::LPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src,
        mod_cutoff => {},
        mod_q => {}
    );

    is_deeply $got, $expected, "LPF with modulation";
}

{
    my $expected = Cassis::Iir2::HPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src
    );
    my $got = Cassis::Iir2::HPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src,
        mod_cutoff => {},
        mod_q => {}
    );

    is_deeply $got, $expected, "HPF with modulation";
}

{
    my $expected = Cassis::Iir2::BPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src
    );
    my $got = Cassis::Iir2::BPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src,
        mod_cutoff => {},
        mod_q => {}
    );

    is_deeply $got, $expected, "BPF with modulation";
}

{
    my $expected = Cassis::Iir2::BEF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src
    );
    my $got = Cassis::Iir2::BEF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src,
        mod_cutoff => {},
        mod_q => {}
    );

    is_deeply $got, $expected, "BEF with modulation";
}

done_testing;

