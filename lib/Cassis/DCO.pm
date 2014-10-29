package Cassis::DCO;
use strict;
use warnings;

our $TUNING_A4 = 440.0; # at pitch = 4.0

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{fs} ) { die 'fs parameter is required.'; }
    if ( $args{fs} <= 0 ) { die 'fs parameter must be greater than 0.'; }

    my $ret = bless {
        fs => $args{fs},
        t => 0.0,
        pitch => 4.0,
        tuning => $TUNING_A4 * (2.0 ** -4.0)
    }, $class;

    if ( exists $args{freq} and exists $args{pitch} ) {
        warn 'Both of the "pitch" and "freq" argument exists.';
    }

    $ret->set_freq( $args{freq} ) if ( exists $args{freq} );
    $ret->set_pitch( $args{pitch} ) if ( exists $args{pitch} );

    $ret;
}

sub set_pitch {
    $_[0]->{pitch} = $_[1];
}

sub pitch {
    $_[0]->{pitch};
}

sub set_freq {
    my ( $self, $freq ) = @_;

    if ( $freq <= 0.0 ) {
        
        
    }

    $self->set_pitch( log($freq / $self->{tuning}) / log(2.0) );
}

sub freq {
    my $self = shift;
    $self->{tuning} * (2.0 ** $self->{pitch});
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{num} ) { die 'num parameter is required.'; }

    my @w_list = ();
    my $t = $self->{t};
    if ( exists $args{mod_pitch} ) {
        my @mod_src = ( exists $args{mod_pitch}->{src} ) ? @{$args{mod_pitch}->{src}} : ();
        my $mod_depth = ( exists $args{mod_pitch}->{depth} ) ? $args{mod_pitch}->{depth} : 1.0;

        if ( scalar(@mod_src) < $args{num} ) {
            warn 'Modulation source is shorter than input.';
            while ( scalar(@mod_src) < $args{num} ) { push @mod_src, 0.0; }
        }

        @w_list = map {
            my $w = $t - int($t);
            $t += $_;
            $w;
        } map {
            my $pitch = $self->{pitch} + ($_ * $mod_depth);
            ($self->{tuning} * (2.0 ** $pitch)) / $self->{fs};
        } @mod_src;
    }
    else {
        my $dt = ($self->{tuning} * (2.0 ** $self->{pitch})) / $self->{fs};
        @w_list = map {
            my $w = $t - int($t);
            $t += $dt;
            $w;
        } 1..$args{num};
    }

    $self->{t} = $t;

    return $self->oscillate( \@w_list, args => \%args );
}

sub oscillate {
    die 'Must be override.';
}

package Cassis::DCO::Sin;
use Math::Trig ':pi';
our @ISA = qw ( Cassis::DCO );

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        sin( 2.0 * pi * $_ );
    } @{$w};

    return \@dst;
}

package Cassis::DCO::Pulse;
our @ISA = qw ( Cassis::DCO );

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        ( $_ < 0.5 ) ? -1.0 : 1.0;
    } @{$w};

    return \@dst;
}

package Cassis::DCO::Saw;
our @ISA = qw ( Cassis::DCO );

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        ( 2.0 * $_ ) - 1.0;
    } @{$w};

    return \@dst;
}

package Cassis::DCO::Tri;
our @ISA = qw ( Cassis::DCO );

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        if ( $_ < 0.5 ) {
            # -1.0 -> +1.0
            -1.0 + ( 4.0 * $_ );
        }
        else {
            # +1.0 -> -1.0
            1.0 - ( 4.0 * ($_ - 0.5) );
        }
    } @{$w};

    return \@dst;
}

1;

__END__

=encoding utf-8

=head1 NAME

Cassis::DCO - Digital Controlled Oscillator

=head1 SYNOPSIS

    use Cassis::DCO;
    
    my $fs = 44100;
    my $dco = Cassis::DCO::Sin->new( fs => $fs );
    my $dst = $dco->exec( num => $fs * 2 ); # 2sec

=head1 DESCRIPTION

=over

=item new()

"fs" is required.

    my $osc = Cassis::DCO::Sin->new(
        fs => 44100     # Sampling rate.
    );
    
    # our $TUNING = 440.0;
    # freq. = $TUNING * (2 ** pitch);
    my $osc = Cassis::DCO::Sin->new(
        fs => 44100,    # Sampling rate.
        pitch => 4.0    # Pitch
    );

=item set_pitch()

    # Set pitch.
    my $pitch = 5.0 + (1.0 / 12.0);
    $dco->set_pitch( $new_pitch );

=item pitch()

    # Get pitch.
    my $pitch = $dco->pitch();

=item exec()

    # Get osillation result.
    my $fs = 44100;
    my $osc = Cassis::DCO::Sin->new( fs => $fs );
    my $dst = $dco->exec( num => $fs * 2 ); # 2sec
    
    # Osillate with modulation.
    my $osc = Cassis::Osc::Pulse->new( fs => $fs, freq => 4 ); # Low Frequency Oscillator
    my $dst = $dco->exec(
        num => $fs * 2,
        mod_pitch => {
            src => $osc->exec( num => $fs * 2 ),
            depth => 1.0 # Modulation between +1 octave from -1 octave.
        }
    );

=back

=head2 Oscillation Type

=over

=item Sin Wave

    my $dco = Cassis::DCO::Sin->new( fs => $fs );

=item Pulse Wave

    my $dco = Cassis::DCO::Pulse->new( fs => $fs );

=item Saw Wave

    my $dco = Cassis::DCO::Saw->new( fs => $fs );

=item Tri Wave

    my $dco = Cassis::DCO::Tri->new( fs => $fs );

=back

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
