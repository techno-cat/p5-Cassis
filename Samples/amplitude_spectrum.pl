#!perl
use strict;
use warnings;

use Cassis;
use Math::Trig ':pi';
use constant N => 1000;

my $cutoff = 0.2;
my $q = 2.5;
my $filter = Cassis::Iir2->new( cutoff => $cutoff, q => $q );

my %filter_params = (
    LPF => $filter->calc_lpf_params(),
    HPF => $filter->calc_hpf_params(),
    BPF => $filter->calc_bpf_params(),
    BEF => $filter->calc_bef_params()
);

foreach my $type ( qw(LPF HPF BPF BEF) ) {
    my $params = $filter_params{$type};
    my $title = sprintf( "%s ( Cutoff: %.3f, Q: %.3f )", $type, $cutoff, $q );

    print "=== $title ===\n";
    foreach my $key ( qw/b0 b1 b2 a1 a2/ ) {
        printf( "%s: %6.3f\n", $key, $params->{$key} );
    }

    my $spectrum = calc_amplitude_spectrum( $params );
    foreach my $data ( @{$spectrum} ) {
        printf( "f: %.3f, Gain: %.3f\n", $data->{f}, $data->{gain} );
    }
}

sub calc_amplitude_spectrum {
    my $params = shift;

    my @spectrum = map {
        my $f = $_ / N;
        my $gain = calc_gain( $f, $params );
        { f => $f, gain => $gain };
    } 0..(N / 2);
 
    return \@spectrum;
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

=encoding utf-8

=head1 NAME

amplitude_spectrum.pl - Amplitude Spectrum

=head1 SYNOPSIS

    $ perl amplitude_spectrum.pl

=head1 DESCRIPTION

    This is a sample script.

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
