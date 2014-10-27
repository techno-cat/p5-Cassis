package Cassis::Osc;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{fs} ) { die 'fs parameter is required.'; }

    bless {
        fs   => $args{fs},
        t    => 0,
        freq => ( exists $args{freq} ) ? $args{freq} : 1.0
    }, $class;
}

sub freq {
    $_[0]->{freq};
}

sub set_freq {
    $_[0]->{freq} = $_[1];
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{num} ) { die 'num parameter is required.'; }

    my @w_list = ();
    my $t = $self->{t};
    if ( exists $args{mod_freq} ) {
        my @mod_src = ( $args{mod_freq}->{src} ) ? @{$args{mod_freq}->{src}} : ();
        my $mod_depth = ( $args{mod_freq}->{depth} ) ? $args{mod_freq}->{depth} : 1.0;

        if ( scalar(@mod_src) < $args{num} ) {
            warn 'Modulation source is shorter than input.';
            while ( scalar(@mod_src) < $args{num} ) { push @mod_src, 0.0; }
        }

        my $mod_range = $self->{freq} * $mod_depth;
        my $freq0 = $self->{freq} - $mod_range;
        @w_list = map {
            my $w = $t - int($t);
            $t += $_;
            $w;
        } map {
            my $freq = $freq0 + ($_ * $mod_range);
            ( $freq < 0.0 ) ? 0.0 : ($freq / $self->{fs});
        } @mod_src;
    }
    else {
        my $dt = $self->{freq} / $self->{fs};
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

package Cassis::Osc::Sin;
use Math::Trig ':pi';
our @ISA = qw ( Cassis::Osc );

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        sin( 2.0 * pi * $_ );
    } @{$w};

    return \@dst;
}

package Cassis::Osc::Pulse;
our @ISA = qw ( Cassis::Osc );

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        ( $_ < 0.5 ) ? -1.0 : 1.0;
    } @{$w};

    return \@dst;
}

package Cassis::Osc::Saw;
our @ISA = qw ( Cassis::Osc );

sub oscillate {
    my $self = shift;
    my ( $w, $args ) = @_;

    my @dst = map {
        ( 2.0 * $_ ) - 1.0;
    } @{$w};

    return \@dst;
}

package Cassis::Osc::Tri;
our @ISA = qw ( Cassis::Osc );

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

Cassis::Osc - Oscillator

=head1 SYNOPSIS

    use Cassis::Osc;
    
    my $osc = Cassis::Osc::Sin->new( fs => 44100, freq => 440 );
    my $dst = $osc->exec( num => 44100 );

=head1 DESCRIPTION

=over

=item new()

"fs" is required.

    my $osc = Cassis::Osc::Sin->new(
        fs => 44100     # Sampling rate.
    );
    
    my $osc = Cassis::Dco::Sin->new(
        fs => 44100,    # Sampling rate.
        freq => 1.0     # Frequency(Hz)
    );

=item freq()

    # Get frequency.
    my $freq = $osc->freq();

=item set_freq()

    # Set frequency.
    my $new_freq = 2.0;
    $osc->set_freq( $new_freq );

=item exec()

    # Get osillation result.
    my $fs = 44100;
    my $osc = Cassis::Osc::Sin->new( fs => $fs );
    my $dst = $osc->exec( num => $fs * 2 ); # 2sec
    
    # Osillate with modulation.
    my $mod = Cassis::Osc::Pulse->new( fs => $fs, freq => 4.0 );
    $dst = $osc->exec( num => 44100, mod_freq => {
        src => $mod->exec( num => 44100 ),
        depth => 0.25
    } );

=back

=head2 Oscillation Type

=over

=item Sin Wave

    my $osc = Cassis::Osc::Sin->new( fs => $fs );

=item Pulse Wave

    my $osc = Cassis::Osc::Pulse->new( fs => $fs );

=item Saw Wave

    my $osc = Cassis::Osc::Saw->new( fs => $fs );

=item Tri Wave

    my $osc = Cassis::Osc::Tri->new( fs => $fs );

=back

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
