package Cassis::Dco;
use strict;
use warnings;

our $TUNING = 440.0;

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{fs} ) { die 'fs parameter is required.'; }

    bless {
        fs => $args{fs},
        t => 0.0,
        voltage => ( exists $args{voltage} ) ? $args{voltage} : 0.0,
        custom_osc => ( exists $args{custom_osc} ) ? $args{custom_osc} : sub { return []; }
    }, $class;
}

sub voltage {
    $_[0]->{voltage};
}

sub set_voltage {
    $_[0]->{voltage} = $_[1];
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{num} ) { die 'num parameter is required.'; }

    my ( $t, $v0, $fs ) = ( $self->{t}, $self->{voltage}, $self->{fs} );
    $args{pitch} = [];
    if ( exists $args{mod_voltage} ) {
        my @src = ( $args{mod_voltage}->{src} ) ? @{$args{mod_voltage}->{src}} : ();
        my $depth = ( $args{mod_voltage}->{depth} ) ? $args{mod_voltage}->{depth} : 1.0;
        push @{$args{pitch}}, map {
            my $ret = $t - int($t);
            my $v = $v0 + (((@src) ? shift @src : 0.0) * $depth);
            my $dt = ($TUNING * (2.0 ** $v)) / $fs;
            $t += $dt;
            $ret;
        } 1..$args{num};
    }
    else {
        my $dt = ($TUNING * (2.0 ** $v0)) / $fs;
        push @{$args{pitch}}, map {
            my $ret = $t - int($t);
            $t += $dt;
            $ret;
        } 1..$args{num};
    }

    $self->{t} = $t;

    return $self->oscillate( %args );
}

sub oscillate {
    my $self = shift;
    my %args = @_;

    return $self->{custom_osc}->( %args );
}

package Cassis::Dco::Sin;
our @ISA = qw(Cassis::Dco);
use Math::Trig ':pi';

sub oscillate {
    my $self = shift;
    my %args = @_;

    my @dst = map {
        sin( 2.0 * pi * $_ );
    } @{$args{pitch}};

    return \@dst;
}

package Cassis::Dco::Pulse;
our @ISA = qw(Cassis::Dco);

sub oscillate {
    my $self = shift;
    my %args = @_;

    my @dst = map {
        ( $_ < 0.5 ) ? -1.0 : 1.0;;
    } @{$args{pitch}};

    return \@dst;
}

package Cassis::Dco::Saw;
our @ISA = qw(Cassis::Dco);

sub oscillate {
    my $self = shift;
    my %args = @_;

    my @dst = map {
        ( 2.0 * $_ ) - 1.0;
    } @{$args{pitch}};

    return \@dst;
}

package Cassis::Dco::Tri;
our @ISA = qw(Cassis::Dco);

sub oscillate {
    my $self = shift;
    my %args = @_;

    my @dst = map {
        if ( $_ < 0.5 ) {
            # -1.0 -> +1.0
            -1.0 + ( 4.0 * $_ );
        }
        else {
            # +1.0 -> -1.0
            1.0 - ( 4.0 * ($_ - 0.5) );
        }
    } @{$args{pitch}};

    return \@dst;
}

1;

__END__

=encoding utf-8

=head1 NAME

Cassis::Dco - Digital Controlled Oscillator

=head1 SYNOPSIS

    use Cassis::Dco;

    ...

=head1 DESCRIPTION

    ...

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
