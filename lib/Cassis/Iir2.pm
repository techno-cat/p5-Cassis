package Cassis::Iir2;

use strict;
use warnings;
use Math::Trig qw(pi tan);

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{cutoff} ) { die 'cutoff parameter is required.'; }
    if ( not exists $args{q}      ) { die 'q parameter is required.';      }

    ( $args{z_m1}, $args{z_m2} ) = ( .0, .0 );

    bless \%args, $class;
}

sub lpf {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }
    my @mod = ( exists $args{mod} ) ? @{$args{mod}} : ();

    my ( $cutoff, $q ) = ( $self->{cutoff}, $self->{q} );
    my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );

    my @dst = map {
        my $new_cutoff = $cutoff + ( (@mod) ? shift @mod : 0 );
        $new_cutoff = ( $new_cutoff < .0 ) ? .0 : ((.5 < $new_cutoff) ? .5 : $new_cutoff);
        my $fc = tan(pi * $new_cutoff) / (2.0 * pi);
        my $_2_pi_fc = 2.0 * pi * $fc;
        my $_4_pi_pi_fc_fc = $_2_pi_fc * $_2_pi_fc;
        my $d = 1.0 + ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc; # 各係数の分母

        my $b = $_4_pi_pi_fc_fc / $d;
        #my $b0 = $_4_pi_pi_fc_fc / $d;
        #my $b1 = (2.0 * $_4_pi_pi_fc_fc) / $d;
        #my $b2 = $_4_pi_pi_fc_fc / $d;
        my $a1 = ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d;
        my $a2 = (1.0 - ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc) / $d;

        my $in = $_ - (($z_m2 * $a2) + ($z_m1 * $a1));
        #my $ret = ($z_m2 * $b2) + ($z_m1 * $b1) + ($in * $b0);
        my $ret = ($z_m2 + ($z_m1 * 2.0) + $in) * $b;
        ( $z_m2, $z_m1 ) = ( $z_m1, $in );

        $ret;
    } @{$args{src}};

    ( $self->{z_m1}, $self->{z_m2} ) = ( $z_m1, $z_m2 );

    return \@dst;
}

1;

__END__

=encoding utf-8

=head1 NAME

Cassis::Iir2 - Second-order IIR digital filter

=head1 SYNOPSIS

    use Cassis::Iir2;
    use Math::Trig ':pi';

    # Pulse Wave
    my @src = map { sin((2.0 * pi) * 0.005 * $_) < 0 ? -.5 : +.5; } 0..511;

    my $cutoff = 0.02;
    my $q = 1.0 / sqrt(2.0);
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );

    my $dst = $f->lpf( src => \@src );

=head1 DESCRIPTION

    # LPF(Low Pass Filter)

    my $dst = $filter->lpf( src => \@src );
    my $dst = $filter->lpf( src => \@src, mod => \@modulation_source );

    # HPF(High Pass Filter)

    Sorry, now working...

    # BPF(Band Pass Filter)

    Sorry, now working...

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
