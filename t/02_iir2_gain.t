use strict;
use Test::More 0.98;
use List::Util qw(sum);
use Math::Trig ":pi";

use_ok $_ for qw(
    Cassis
);

my $th = 0.001;
my $q = 1.0 / sqrt(2.0);
foreach my $cutoff ( $Cassis::Iir2::CUTOFF_MIN, $Cassis::Iir2::CUTOFF_MAX ) {
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );

    {
        my $params = $f->calc_lpf_params();
        ok( abs(calc_gain($cutoff, $params) - $q) < $th, "LPF(Cutoff: $cutoff, Q: $q)" );
    }

    {
        my $params = $f->calc_hpf_params();
        ok( abs(calc_gain($cutoff, $params) - $q) < $th, "HPF(Cutoff: $cutoff, Q: $q)" );
    }

    {
        my $params = $f->calc_bpf_params();
        my $gain = calc_gain( $cutoff, $params );
        ok( (1.0 - $gain) < $th, "BPF(Cutoff: $cutoff, Q: $q)" );
        ok( calc_gain($cutoff + 0.0005, $params) < $gain, "BPF(Cutoff: $cutoff, Q: $q)" );
        ok( calc_gain($cutoff - 0.0005, $params) < $gain, "BPF(Cutoff: $cutoff, Q: $q)" );
    }

    {
        my $params = $f->calc_bef_params();
        my $gain = calc_gain( $cutoff, $params );
        ok( $gain < $th, "BEF(Cutoff: $cutoff, Q: $q)" );
        ok( $gain < calc_gain($cutoff + 0.0005, $params), "BEF(Cutoff: $cutoff, Q: $q)" );
        ok( $gain < calc_gain($cutoff - 0.0005, $params), "BEF(Cutoff: $cutoff, Q: $q)" );
    }
}

sub calc_gain {
    my ( $w, $params ) = @_;

    # H(z) = (b0 + b1 * z^-1 + b2 * z^-2) / (1 + a1 * z^-1 + a2 * z^-2)
    # z^1  = e^(jw)  = cos(w) + j*sin(w)
    # z^-1 = e^(-jw) = cos(w) - j*sin(w)

    # H(jw) = {(A-jB) * (C+jD)} / {(C-jD) * (C+jD)} = {(AC + BD) + j(AD - BC)} / (C^2 + D^2)
    # |H(jw)| = sqrt( (AC + BD)^2 + (AD - BC)^2 ) / (C^2 + D^2)

    my ( $b0, $b1, $b2, $a1, $a2 ) = map { $params->{$_}; } qw(b0 b1 b2 a1 a2);
    my $sin_w = sin( 2.0 * pi * $w );
    my $sin_2w = sin( 2.0 * pi * 2.0 * $w );
    my $cos_w = cos( 2.0 * pi * $w );
    my $cos_2w = cos( 2.0 * pi * 2.0 * $w );

    my $largeA = $b0 + ($b1 * $cos_w) + ($b2 * $cos_2w);
    my $largeB = ($b1 * $sin_w) + ($b2 * $sin_2w);
    my $largeC = 1.0 + ($a1 * $cos_w) + ($a2 * $cos_2w);
    my $largeD = ($a1 * $sin_w) + ($a2 * $sin_2w);

    my $AC_plus_BD = ($largeA * $largeC) + ($largeB * $largeD);
    my $AD_minus_BC = ($largeA * $largeD) - ($largeB * $largeC);
    my $d = ($largeC * $largeC) + ($largeD * $largeD);

    my $gain = sqrt(($AC_plus_BD * $AC_plus_BD) + ($AD_minus_BC * $AD_minus_BC)) / $d;

    return $gain;
}

done_testing;

