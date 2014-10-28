use strict;
use Test::More 0.98;
use List::Util qw(sum);

use_ok $_ for qw(
    Cassis::Iir2
);

can_ok 'Cassis::Iir2', qw/new exec params set_cutoff cutoff set_q q/;

my @src = map { 64 < ($_ % 128) ? -1.0 : 1.0; } 0..511;
my @mod_src = map { 0.0; } 0..511;

my $cutoff = 0.05;
my $q = 1.0 / sqrt(2.0);
my $th = 1.0e-10;
{
    my $expected = Cassis::Iir2::LPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src
    );
    my $got = Cassis::Iir2::LPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src,
        mod_cutoff => {
            src => \@mod_src, depth => 1.0
        },
        mod_q => {
            src => \@mod_src, depth => 1.0
        }
    );

    ok( diff_total($got, $expected) < $th, "LPF with modulation" );
}

{
    my $expected = Cassis::Iir2::HPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src
    );
    my $got = Cassis::Iir2::HPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src,
        mod_cutoff => {
            src => \@mod_src, depth => 1.0
        },
        mod_q => {
            src => \@mod_src, depth => 1.0
        }
    );

    ok( diff_total($got, $expected) < $th, "HPF with modulation" );
}

{
    my $expected = Cassis::Iir2::BPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src
    );
    my $got = Cassis::Iir2::BPF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src,
        mod_cutoff => {
            src => \@mod_src, depth => 1.0
        },
        mod_q => {
            src => \@mod_src, depth => 1.0
        }
    );

    ok( diff_total($got, $expected) < $th, "BPF with modulation" );
}

{
    my $expected = Cassis::Iir2::BEF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src
    );
    my $got = Cassis::Iir2::BEF->new( cutoff => $cutoff, q => $q )->exec(
        src => \@src,
        mod_cutoff => {
            src => \@mod_src, depth => 1.0
        },
        mod_q => {
            src => \@mod_src, depth => 1.0
        }
    );

    ok( diff_total($got, $expected) < $th, "BEF with modulation" );
}

sub diff_total {
    my ( $array1, $arrey2 ) = @_;

    my $n = scalar @{$array1};
    return sum( map {
        abs($array1->[$_] - $arrey2->[$_]);
    } 0..($n - 1) ); 
}

done_testing;

