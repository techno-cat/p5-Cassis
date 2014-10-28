package Cassis::Iir2;
use strict;
use warnings;

our $CUTOFF_MIN = 0.001;
our $CUTOFF_MAX = 0.499;
our $Q_MIN = 0.01;

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{cutoff} ) { die 'cutoff parameter is required.'; }
    if ( not exists $args{q}      ) { die 'q parameter is required.';      }

    my $ret = bless {
        cutoff => 0.1,
        q => 1.0 / sqrt(2.0),
        z_m1 => 0.0,
        z_m2 => 0.0
    }, $class;

    $ret->set_cutoff( $args{cutoff} );
    $ret->set_q( $args{q} );

    $ret;
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    my $params = $self->params();
    my ( $b0, $b1, $b2, $a1, $a2 ) = map { $params->{$_}; } qw(b0 b1 b2 a1 a2);

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

sub set_cutoff {
    my ( $self, $cutoff ) = @_;

    if ( $cutoff < $CUTOFF_MIN ) {
        warn "cutoff is clipped. ($cutoff -> $CUTOFF_MIN)";
        $cutoff = $CUTOFF_MIN;
    }
    elsif ( $CUTOFF_MAX < $cutoff ) {
        warn "cutoff is clipped. ($cutoff -> $CUTOFF_MAX)";
        $cutoff = $CUTOFF_MAX;
    }

    $self->{cutoff} = $cutoff;
}

sub cutoff {
    $_[0]->{cutoff};
}

sub set_q {
    my ( $self, $q ) = @_;

    if ( $q < $Q_MIN ) {
        warn "q is clipped. ($q -> $Q_MIN)";
        $q = $Q_MIN;
    }

    $self->{q} = $q;
}

sub q {
    $_[0]->{q};
}

sub params {
    die 'Must be override.';
}

package Cassis::Iir2::LPF;
use Math::Trig qw(pi tan);
our @ISA = qw( Cassis::Iir2 );

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    if ( exists $args{mod_cutoff} or exists $args{mod_q} ) {
        my $n = scalar(@{$args{src}});

        my @cutoff_src = ( exists $args{mod_cutoff}->{src} ) ? @{$args{mod_cutoff}->{src}} : map { 0; } 1..$n;
        my $cutoff_depth = ( exists $args{mod_cutoff}->{depth} ) ? $args{mod_cutoff}->{depth} : 1.0;

        if ( scalar(@cutoff_src) < $n ) {
            warn 'Cutoff modulation source is shorter than input.';
            while ( scalar(@cutoff_src) < $n ) { push @cutoff_src, 0.0; }
        }

        my @q_src = ( exists $args{mod_q}->{src} ) ? @{$args{mod_q}->{src}} : map { 0; } 1..$n;
        my $q_depth = ( exists $args{mod_q}->{depth} ) ? $args{mod_q}->{depth} : 1.0;

        if ( scalar(@q_src) < $n ) {
            warn 'Q modulation source is shorter than input.';
            while ( scalar(@q_src) < $n ) { push @q_src, 0.0; }
        }

        my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );
        my @dst = map {
            my $cutoff = $self->{cutoff} + ((shift @cutoff_src) * $cutoff_depth);
            $cutoff = ( $cutoff < $CUTOFF_MIN ) ? $CUTOFF_MIN : (($CUTOFF_MAX < $cutoff) ? $CUTOFF_MAX : $cutoff);
            my $q = $self->{q} + ((shift @q_src) * $q_depth);
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
    else {
        return $self->SUPER::exec( %args );
    }
}

sub params {
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

package Cassis::Iir2::HPF;
use Math::Trig qw(pi tan);
our @ISA = qw( Cassis::Iir2 );

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    if ( exists $args{mod_cutoff} or exists $args{mod_q} ) {
        my $n = scalar(@{$args{src}});

        my @cutoff_src = ( exists $args{mod_cutoff}->{src} ) ? @{$args{mod_cutoff}->{src}} : map { 0; } 1..$n;
        my $cutoff_depth = ( exists $args{mod_cutoff}->{depth} ) ? $args{mod_cutoff}->{depth} : 1.0;

        if ( scalar(@cutoff_src) < $n ) {
            warn 'Cutoff modulation source is shorter than input.';
            while ( scalar(@cutoff_src) < $n ) { push @cutoff_src, 0.0; }
        }

        my @q_src = ( exists $args{mod_q}->{src} ) ? @{$args{mod_q}->{src}} : map { 0; } 1..$n;
        my $q_depth = ( exists $args{mod_q}->{depth} ) ? $args{mod_q}->{depth} : 1.0;

        if ( scalar(@q_src) < $n ) {
            warn 'Q modulation source is shorter than input.';
            while ( scalar(@q_src) < $n ) { push @q_src, 0.0; }
        }

        my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );
        my @dst = map {
            my $cutoff = $self->{cutoff} + ((shift @cutoff_src) * $cutoff_depth);
            $cutoff = ( $cutoff < $CUTOFF_MIN ) ? $CUTOFF_MIN : (($CUTOFF_MAX < $cutoff) ? $CUTOFF_MAX : $cutoff);
            my $q = $self->{q} + ((shift @q_src) * $q_depth);
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
            #my $ret = ($b0 * $in) + ($b1 * $z_m1) + ($b2 * $z_m2);
            my $ret = ($in + (-2.0 * $z_m1) + $z_m2) / $d;
            ( $z_m2, $z_m1 ) = ( $z_m1, $in );

            $ret;
        } @{$args{src}};

        ( $self->{z_m1}, $self->{z_m2} ) = ( $z_m1, $z_m2 );

        return \@dst;
    }
    else {
        return $self->SUPER::exec( %args );
    }
}

sub params {
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

package Cassis::Iir2::BPF;
use Math::Trig qw(pi tan);
our @ISA = qw( Cassis::Iir2 );

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    if ( exists $args{mod_cutoff} or exists $args{mod_q} ) {
        my $n = scalar(@{$args{src}});

        my @cutoff_src = ( exists $args{mod_cutoff}->{src} ) ? @{$args{mod_cutoff}->{src}} : map { 0; } 1..$n;
        my $cutoff_depth = ( exists $args{mod_cutoff}->{depth} ) ? $args{mod_cutoff}->{depth} : 1.0;

        if ( scalar(@cutoff_src) < $n ) {
            warn 'Cutoff modulation source is shorter than input.';
            while ( scalar(@cutoff_src) < $n ) { push @cutoff_src, 0.0; }
        }

        my @q_src = ( exists $args{mod_q}->{src} ) ? @{$args{mod_q}->{src}} : map { 0; } 1..$n;
        my $q_depth = ( exists $args{mod_q}->{depth} ) ? $args{mod_q}->{depth} : 1.0;

        if ( scalar(@q_src) < $n ) {
            warn 'Q modulation source is shorter than input.';
            while ( scalar(@q_src) < $n ) { push @q_src, 0.0; }
        }

        my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );
        my @dst = map {
            my $cutoff = $self->{cutoff} + ((shift @cutoff_src) * $cutoff_depth);
            $cutoff = ( $cutoff < $CUTOFF_MIN ) ? $CUTOFF_MIN : (($CUTOFF_MAX < $cutoff) ? $CUTOFF_MAX : $cutoff);
            my $q = $self->{q} + ((shift @q_src) * $q_depth);
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
            #my $ret = ($b0 * $in) + ($b1 * $z_m1) + ($b2 * $z_m2);
            my $ret = $b * ($in - $z_m2);
            ( $z_m2, $z_m1 ) = ( $z_m1, $in );

            $ret;
        } @{$args{src}};

        ( $self->{z_m1}, $self->{z_m2} ) = ( $z_m1, $z_m2 );

        return \@dst;
    }
    else {
        return $self->SUPER::exec( %args );
    }
}

sub params {
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

package Cassis::Iir2::BEF;
use Math::Trig qw(pi tan);
our @ISA = qw( Cassis::Iir2 );

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    if ( exists $args{mod_cutoff} or exists $args{mod_q} ) {
        my $n = scalar(@{$args{src}});

        my @cutoff_src = ( exists $args{mod_cutoff}->{src} ) ? @{$args{mod_cutoff}->{src}} : map { 0; } 1..$n;
        my $cutoff_depth = ( exists $args{mod_cutoff}->{depth} ) ? $args{mod_cutoff}->{depth} : 1.0;

        if ( scalar(@cutoff_src) < $n ) {
            warn 'Cutoff modulation source is shorter than input.';
            while ( scalar(@cutoff_src) < $n ) { push @cutoff_src, 0.0; }
        }

        my @q_src = ( exists $args{mod_q}->{src} ) ? @{$args{mod_q}->{src}} : map { 0; } 1..$n;
        my $q_depth = ( exists $args{mod_q}->{depth} ) ? $args{mod_q}->{depth} : 1.0;

        if ( scalar(@q_src) < $n ) {
            warn 'Q modulation source is shorter than input.';
            while ( scalar(@q_src) < $n ) { push @q_src, 0.0; }
        }

        my ( $z_m1, $z_m2 ) = ( $self->{z_m1}, $self->{z_m2} );
        my @dst = map {
            my $cutoff = $self->{cutoff} + ((shift @cutoff_src) * $cutoff_depth);
            $cutoff = ( $cutoff < $CUTOFF_MIN ) ? $CUTOFF_MIN : (($CUTOFF_MAX < $cutoff) ? $CUTOFF_MAX : $cutoff);
            my $q = $self->{q} + ((shift @q_src) * $q_depth);
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
    else {
        return $self->SUPER::exec( %args );
    }
}

sub params {
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
    my $f = Cassis::Iir2::LPF->new( cutoff => $cutoff, q => $q );

    my $dst = $f->exec( src => \@src );

=head1 DESCRIPTION

=head2 Cutoff parameter

    # our $CUTOFF_MIN => 0.001;
    # our $CUTOFF_MAX => 0.499;
    # $CUTOFF_MIN <= Cutoff <= $CUTOFF_MAX

=head2 Q - Resonance

    our $Q_MIN = 0.01;
    $Q_MIN <= Q

=over

=item new()

"cutoff", "q" are required.

    my $f = Cassis::Iir2::LPF->new( cutoff => 0.1, q => 2.0 );

=item set_cutoff()

    # Set cutoff.
    my $new_cutoff = 0.2;
    $f->set_cutoff( $new_cutoff );

=item cutoff()

    # Get cutoff.
    my $cutoff = $f->cutoff();

=item set_q()

    # Set q.
    my $new_q = 0.2;
    $f->set_q( $new_q );

=item q()

    # Get q.
    my $q = $f->q();

=item params()

    my $paramse = $f->params(); # => { b0 => $b0, b1 => $b1, b2 => $b2, a1 => $a1, a2 => $a2 }

=item exec()

    # Simple Filtering
    my $dst = $f->exec( src => \@src );

    # With Modulation
    my $dst = $f->exec(
        src => \@src,
        mod_cutoff => {
            src => \@modulation_source }, depth = 1.0
        }
    );
    my $dst = $f->exec(
        src => \@src,
        mod_q => {
            src => \@modulation_source }, depth = 1.0
        }
    );
    my $dst = $f->exec(
        src => \@src,
         mod_cutoff => {
            src => \@modulation_source }, depth = 1.0
        },
        mod_q => {
            src => \@modulation_source }, depth = 1.0
        }
    );

If array length of modulation-source is little than source,
0 is using as modulation value.

=back

=head2 Filter Type

=over

=item Cassis::Iir2::LPF

    Low Pass Filter

=item Cassis::Iir2::HPF

    High Pass Filter

=item Cassis::Iir2::BPF

    Band Pass Filter

=item Cassis::Iir2::BEF

    Band Elimination Filter

=back

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
