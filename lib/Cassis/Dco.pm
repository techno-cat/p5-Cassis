package Cassis::Dco;
use strict;
use warnings;

our $TUNING_A4 = 440.0; # at pitch = 4.0

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{fs} ) { die 'fs parameter is required.'; }

    bless {
        fs => $args{fs},
        t => 0.0,
        pitch => ( exists $args{pitch} ) ? $args{pitch} : 0.0,
        tuning => $TUNING_A4 * (2.0 ** -4)
    }, $class;
}

sub pitch {
    $_[0]->{pitch};
}

sub set_pitch {
    $_[0]->{pitch} = $_[1];
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{num} ) { die 'num parameter is required.'; }

    my @ret = ();
    my $t = $self->{t};
    if ( exists $args{mod_pitch} ) {
        my @src = ( $args{mod_pitch}->{src} ) ? @{$args{mod_pitch}->{src}} : ();
        my $depth = ( $args{mod_pitch}->{depth} ) ? $args{mod_pitch}->{depth} : 1.0;

        if ( scalar(@src) < $args{num} ) {
            warn 'Modulation source is shorter than input.';
            while ( scalar(@src) < $args{num} ) { push @src, 0.0; }
        }

        @ret = map {
            my $w = $t - int($t);
            $t += $_;
            $w;
        } map {
            my $pitch = $self->{pitch} + ($_ * $depth);
            ($self->{tuning} * (2.0 ** $pitch)) / $self->{fs};
        } @src;
    }
    else {
        my $dt = ($self->{tuning} * (2.0 ** $self->{pitch})) / $self->{fs};
        @ret = map {
            my $w = $t - int($t);
            $t += $dt;
            $w;
        } 1..$args{num};
    }

    $self->{t} = $t;

    return $self->oscillate( \@ret, args => \%args );
}

sub oscillate {
    die 'Must be override.';
}

package Cassis::Dco::Sin;
our @ISA = qw(Cassis::Dco);
use Math::Trig ':pi';

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        sin( 2.0 * pi * $_ );
    } @{$w};

    return \@dst;
}

package Cassis::Dco::Pulse;
our @ISA = qw(Cassis::Dco);

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        ( $_ < 0.5 ) ? -1.0 : 1.0;;
    } @{$w};

    return \@dst;
}

package Cassis::Dco::Saw;
our @ISA = qw(Cassis::Dco);

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        ( 2.0 * $_ ) - 1.0;
    } @{$w};

    return \@dst;
}

package Cassis::Dco::Tri;
our @ISA = qw(Cassis::Dco);

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

Cassis::Dco - Digital Controlled Oscillator

=head1 SYNOPSIS

    use Cassis::Dco;

    my $fs = 44100;
    my $dco = Cassis::Dco::Sin->new( fs => $fs );
    my $dst = $dco->exec( num => $fs * 2 ); # 2sec

=head1 DESCRIPTION

=over

=item new()

    # "fs" is sampling-rate.
    my $dco = Cassis::Dco::Sin->new( fs => $fs );

    # our $TUNING = 440.0;
    # frequency = $TUNING * (2 ** pitch);
    my $dco = Cassis::Dco::Sin->new( fs => $fs, pitch => 1.0 );

=item pitch()

    # Get pitch.
    my $pitch = $dco->pitch();

=item set_pitch()

    # Set pitch.
    $dco->set_pitch( $new_pitch );

=item exec()

    # Get osillation result.
    my $dst = $dco->exec( num => $fs * 2 ); # 2sec

    # Osillate with modulation.
    my $lfo = Cassis::Dco::Pulse->new( fs => $fs, pitch => -5 ); # Low Frequency Oscillator
    my $dst = $dco->exec(
        num => $fs * 2,
        mod_pitch => {
            src => $lfo->exec( num => $fs * 2 ), depth => 1.0
        }
    );

=back

=head2 Oscillation Type

=over

=item Sin Wave

    my $dco = Cassis::Dco::Sin->new( fs => $fs );

=item Pulse Wave

    my $dco = Cassis::Dco::Pulse->new( fs => $fs );

=item Saw Wave

    my $dco = Cassis::Dco::Saw->new( fs => $fs );

=item Tri Wave

    my $dco = Cassis::Dco::Tri->new( fs => $fs );

=back

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
