package Cassis::Iir2;

use strict;
use warnings;
use Math::Trig qw(pi tan);
use constant CUTOFF_MIN => 0.0;
use constant CUTOFF_MAX => 0.5;

our $Q_MIN = 0.01;

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{cutoff} ) { die 'cutoff parameter is required.'; }
    if ( not exists $args{q}      ) { die 'q parameter is required.';      }

    my ( $cutoff, $q ) = ( $args{cutoff}, $args{q} );
    $cutoff = ( $cutoff < CUTOFF_MIN ) ? CUTOFF_MIN : ((CUTOFF_MAX < $cutoff) ? CUTOFF_MAX : $cutoff);
    $q = ( $q < $Q_MIN ) ? $Q_MIN : $q;

    bless {
        cutoff => $cutoff,
        q => $q,
        z_m1 => 0.0,
        z_m2 => 0.0
    }, $class;
}

sub lpf {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    my @mod_cutoff = ();
    my @mod_q = ();
    if ( exists $args{mod} ) {
        @mod_cutoff = @{$args{mod}->{cutoff}} if ( exists $args{mod}->{cutoff} );
        @mod_q = @{$args{mod}->{q}} if ( exists $args{mod}->{q} );
    }

    my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );
    my @dst = map {
        my $cutoff = $self->{cutoff} + ( (@mod_cutoff) ? shift @mod_cutoff : 0.0 );
        $cutoff = ( $cutoff < CUTOFF_MIN ) ? CUTOFF_MIN : ((CUTOFF_MAX < $cutoff) ? CUTOFF_MAX : $cutoff);
        my $q = $self->{q} + ( (@mod_q) ? shift @mod_q : 0.0 );
        $q = ( $q < $Q_MIN ) ? $Q_MIN : $q;

        my $fc = tan(pi * $cutoff) / (2.0 * pi);
        my $_2_pi_fc = 2.0 * pi * $fc;
        my $_4_pi_pi_fc_fc = $_2_pi_fc * $_2_pi_fc;
        my $d = 1.0 + ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc;

        my $b = $_4_pi_pi_fc_fc / $d;
        #my $b0 = $_4_pi_pi_fc_fc / $d;
        #my $b1 = (2.0 * $_4_pi_pi_fc_fc) / $d;
        #my $b2 = $_4_pi_pi_fc_fc / $d;
        my $a1 = ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d;
        my $a2 = (1.0 - ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc) / $d;

        my $in = $_ - (($a1 * $z_m1) + ($a2 * $z_m2));
        #my $ret = ($b0 * $in) + ($b1 * $z_m1) + ($b2 * $z_m2);
        my $ret = $b * ($in + (2.0 * $z_m1) + $z_m2);
        ( $z_m2, $z_m1 ) = ( $z_m1, $in );

        $ret;
    } @{$args{src}};

    ( $self->{z_m1}, $self->{z_m2} ) = ( $z_m1, $z_m2 );

    return \@dst;
}

sub calc_lpf_params {
    my $self = shift;
    my ( $cutoff, $q ) = ( $self->{cutoff}, $self->{q} );

    my $fc = tan(pi * $cutoff) / (2.0 * pi);
    my $_2_pi_fc = 2.0 * pi * $fc;
    my $_4_pi_pi_fc_fc = $_2_pi_fc * $_2_pi_fc;
    my $d = 1.0 + ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc;

    return {
        b0 => $_4_pi_pi_fc_fc / $d,
        b1 => (2.0 * $_4_pi_pi_fc_fc) / $d,
        b2 => $_4_pi_pi_fc_fc / $d,
        a1 => ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d,
        a2 => (1.0 - ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc) / $d
    };
}

sub hpf {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    my @mod_cutoff = ();
    my @mod_q = ();
    if ( exists $args{mod} ) {
        @mod_cutoff = @{$args{mod}->{cutoff}} if ( exists $args{mod}->{cutoff} );
        @mod_q = @{$args{mod}->{q}} if ( exists $args{mod}->{q} );
    }

    my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );
    my @dst = map {
        my $cutoff = $self->{cutoff} + ( (@mod_cutoff) ? shift @mod_cutoff : 0.0 );
        $cutoff = ( $cutoff < CUTOFF_MIN ) ? CUTOFF_MIN : ((CUTOFF_MAX < $cutoff) ? CUTOFF_MAX : $cutoff);
        my $q = $self->{q} + ( (@mod_q) ? shift @mod_q : 0.0 );
        $q = ( $q < $Q_MIN ) ? $Q_MIN : $q;

        my $fc = tan(pi * $cutoff) / (2.0 * pi);
        my $_2_pi_fc = 2.0 * pi * $fc;
        my $_4_pi_pi_fc_fc = $_2_pi_fc * $_2_pi_fc;
        my $d = 1.0 + ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc;

        #my $b0 =  1.0 / $d;
        #my $b1 = -2.0 / $d;
        #my $b2 =  1.0 / $d;
        my $a1 = ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d;
        my $a2 = (1.0 - ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc) / $d;

        my $in = $_ - (($z_m2 * $a2) + ($z_m1 * $a1));
        #my $ret = ($z_m2 * $b2) + ($z_m1 * $b1) + ($in * $b0);
        my $ret = ($in + (-2.0 * $z_m1) + $z_m2) / $d;
        ( $z_m2, $z_m1 ) = ( $z_m1, $in );

        $ret;
    } @{$args{src}};

    ( $self->{z_m1}, $self->{z_m2} ) = ( $z_m1, $z_m2 );

    return \@dst;
}

sub calc_hpf_params {
    my $self = shift;
    my ( $cutoff, $q ) = ( $self->{cutoff}, $self->{q} );

    my $fc = tan(pi * $cutoff) / (2.0 * pi);
    my $_2_pi_fc = 2.0 * pi * $fc;
    my $_4_pi_pi_fc_fc = $_2_pi_fc * $_2_pi_fc;
    my $d = 1.0 + ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc;

    return {
        b0 =>  1.0 / $d,
        b1 => -2.0 / $d,
        b2 =>  1.0 / $d,
        a1 => ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d,
        a2 => (1.0 - ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc) / $d
    };
}

sub bpf {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    my @mod_cutoff = ();
    my @mod_q = ();
    if ( exists $args{mod} ) {
        @mod_cutoff = @{$args{mod}->{cutoff}} if ( exists $args{mod}->{cutoff} );
        @mod_q = @{$args{mod}->{q}} if ( exists $args{mod}->{q} );
    }

    my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );
    my @dst = map {
        my $cutoff = $self->{cutoff} + ( (@mod_cutoff) ? shift @mod_cutoff : 0.0 );
        $cutoff = ( $cutoff < CUTOFF_MIN ) ? CUTOFF_MIN : ((CUTOFF_MAX < $cutoff) ? CUTOFF_MAX : $cutoff);
        my $q = $self->{q} + ( (@mod_q) ? shift @mod_q : 0.0 );
        $q = ( $q < $Q_MIN ) ? $Q_MIN : $q;

        my $fc = tan(pi * $cutoff) / (2.0 * pi);
        my $_2_pi_fc = 2.0 * pi * $fc;
        my $_4_pi_pi_fc_fc = $_2_pi_fc * $_2_pi_fc;
        my $d = 1.0 + ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc;

        my $b = ($_2_pi_fc / $q) / $d;
        #my $b0 =  ($_2_pi_fc / $q) / $d;
        #my $b1 = 0.0;
        #my $b2 = -($_2_pi_fc / $q) / $d;
        my $a1 = ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d;
        my $a2 = (1.0 - ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc) / $d;

        my $in = $_ - (($z_m2 * $a2) + ($z_m1 * $a1));
        #my $ret = ($z_m2 * $b2) + ($z_m1 * $b1) + ($in * $b0);
        my $ret = $b * ($in - $z_m2);
        ( $z_m2, $z_m1 ) = ( $z_m1, $in );

        $ret;
    } @{$args{src}};

    ( $self->{z_m1}, $self->{z_m2} ) = ( $z_m1, $z_m2 );

    return \@dst;
}

sub calc_bpf_params {
    my $self = shift;
    my ( $cutoff, $q ) = ( $self->{cutoff}, $self->{q} );

    my $fc = tan(pi * $cutoff) / (2.0 * pi);
    my $_2_pi_fc = 2.0 * pi * $fc;
    my $_4_pi_pi_fc_fc = $_2_pi_fc * $_2_pi_fc;
    my $d = 1.0 + ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc;

    return {
        b0 =>  ($_2_pi_fc / $q) / $d,
        b1 => 0.0,
        b2 => -($_2_pi_fc / $q) / $d,
        a1 => ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d,
        a2 => (1.0 - ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc) / $d
    };
}

sub bef {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    my @mod_cutoff = ();
    my @mod_q = ();
    if ( exists $args{mod} ) {
        @mod_cutoff = @{$args{mod}->{cutoff}} if ( exists $args{mod}->{cutoff} );
        @mod_q = @{$args{mod}->{q}} if ( exists $args{mod}->{q} );
    }

    my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );
    my @dst = map {
        my $cutoff = $self->{cutoff} + ( (@mod_cutoff) ? shift @mod_cutoff : 0.0 );
        $cutoff = ( $cutoff < CUTOFF_MIN ) ? CUTOFF_MIN : ((CUTOFF_MAX < $cutoff) ? CUTOFF_MAX : $cutoff);
        my $q = $self->{q} + ( (@mod_q) ? shift @mod_q : 0.0 );
        $q = ( $q < $Q_MIN ) ? $Q_MIN : $q;

        my $fc = tan(pi * $cutoff) / (2.0 * pi);
        my $_2_pi_fc = 2.0 * pi * $fc;
        my $_4_pi_pi_fc_fc = $_2_pi_fc * $_2_pi_fc;
        my $d = 1.0 + ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc;

        my $b0 = ($_4_pi_pi_fc_fc + 1.0) / $d;
        my $b1 = ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d;
        #my $b2 = ($_4_pi_pi_fc_fc + 1.0) / $d;
        my $a1 = ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d;
        my $a2 = (1.0 - ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc) / $d;

        my $in = $_ - (($z_m2 * $a2) + ($z_m1 * $a1));
        #my $ret = ($b0 * $in) + ($b1 * $z_m1) + ($b2 * $z_m2);
        my $ret = ($b0 * ($in + $z_m2)) + ($b1 * $z_m1);
        ( $z_m2, $z_m1 ) = ( $z_m1, $in );

        $ret;
    } @{$args{src}};

    ( $self->{z_m1}, $self->{z_m2} ) = ( $z_m1, $z_m2 );

    return \@dst;
}

sub calc_bef_params {
    my $self = shift;
    my ( $cutoff, $q ) = ( $self->{cutoff}, $self->{q} );

    my $fc = tan(pi * $cutoff) / (2.0 * pi);
    my $_2_pi_fc = 2.0 * pi * $fc;
    my $_4_pi_pi_fc_fc = $_2_pi_fc * $_2_pi_fc;
    my $d = 1.0 + ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc;

    return {
        b0 => ($_4_pi_pi_fc_fc + 1.0) / $d,
        b1 => ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d,
        b2 => ($_4_pi_pi_fc_fc + 1.0) / $d,
        a1 => ((2.0 * $_4_pi_pi_fc_fc) - 2.0) / $d,
        a2 => (1.0 - ($_2_pi_fc / $q) + $_4_pi_pi_fc_fc) / $d
    };
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }
    if ( not exists $args{params} ) { die 'params parameter is required.'; }

    my ( $b0, $b1, $b2, $a1, $a2 ) = map { $args{params}->{$_}; } qw(b0 b1 b2 a1 a2);

    my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );
    my @dst = map {
        my $in = $_ - (($z_m2 * $a2) + ($z_m1 * $a1));
        my $ret = ($z_m2 * $b2) + ($z_m1 * $b1) + ($in * $b0);
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
    my @src = map { sin((2.0 * pi) * 0.005 * $_) < 0 ? -0.5 : +0.5; } 0..511;

    my $cutoff = 0.02;
    my $q = 1.0 / sqrt(2.0);
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );

    my $dst = $f->lpf( src => \@src );

=head1 DESCRIPTION

    # Cutoff frequency
    0.0 <= freq. <= 0.5

    # Q - Resonance
    our $Q_MIN = 0.01;
    $Q_MIN <= Q

    # LPF(Low Pass Filter)

    my $dst = $filter->lpf( src => \@src );
    my $dst = $filter->lpf( src => \@src, mod => { cutoff => \@modulation_source } );
    my $dst = $filter->lpf( src => \@src, mod => { q => \@modulation_source } );
    my $dst = $filter->lpf( src => \@src, mod => { 
        cutoff => \@modulation_source,
        q      => \@modulation_source
    } );

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
