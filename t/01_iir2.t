use strict;
use Test::More 0.98;
use List::Util qw(sum);

use_ok $_ for qw(
    Cassis
);

my @src = map { 64 < ($_ % 128) ? -1.0 : 1.0 } 0..511;

my $cutoff = 0.05;
my $q = 1.0 / sqrt(2.0);
my $th = 1.e-10;
{
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );
    my $expected = $f->exec( src => \@src, params => $f->calc_lpf_params() );
    my $got = Cassis::Iir2->new( cutoff => $cutoff, q => $q )->lpf(
        src => \@src, mod => { cutoff => [], q => [] } );

    ok( diff_total($got, $expected) < $th, "LPF with modulation" );
}

{
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );
    my $expected = $f->exec( src => \@src, params => $f->calc_hpf_params() );
    my $got = Cassis::Iir2->new( cutoff => $cutoff, q => $q )->hpf(
        src => \@src, mod => { cutoff => [], q => [] } );

    ok( diff_total($got, $expected) < $th, "HPF with modulation" );
}

{
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );
    my $expected = $f->exec( src => \@src, params => $f->calc_bpf_params() );
    my $got = Cassis::Iir2->new( cutoff => $cutoff, q => $q )->bpf(
        src => \@src, mod => { cutoff => [], q => [] } );

    ok( diff_total($got, $expected) < $th, "BPF with modulation" );
}

{
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );
    my $expected = $f->exec( src => \@src, params => $f->calc_bef_params() );
    my $got = Cassis::Iir2->new( cutoff => $cutoff, q => $q )->bef(
        src => \@src, mod => { cutoff => [], q => [] } );

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

