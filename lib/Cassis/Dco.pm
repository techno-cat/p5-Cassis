package Cassis::Dco;

use strict;
use warnings;
use Math::Trig ':pi';

our $TUNING = 440.0;

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{fs} ) { die 'fs parameter is required.'; }

    bless {
        fs => $args{fs},
        t => 0.0,
        voltage => ( exists $args{voltage} ) ? $args{voltage} : 0.0,
        osc => _osc_sin()
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
    if ( exists $args{mod} ) {
        my @mod_v = ( $args{mod}->{voltage} ) ? @{$args{mod}->{voltage}} : ();
        my @pitch = map {
            my $ret = $t;
            my $v = $v0 + ( (@mod_v) ? shift @mod_v : 0 );
            my $dt = ($TUNING * (2.0 ** $v)) / $fs;
            $t += $dt;
            $ret;
        } 1..$args{num};

        $args{mod}->{pitch} = \@pitch;
    }
    else {
        my $dt = ($TUNING * (2.0 ** $v0)) / $fs;
        my @pitch = map {
            my $ret = $t;
            $t += $dt;
            $ret;
        } 1..$args{num};

        $args{mod} = { pitch => \@pitch };
    }

    $self->{t} = $t;

    return $self->{osc}->( %{$args{mod}} );
}

sub exec_once {

}

sub _osc_sin {
    return sub {
        my %args = @_;
        my $vol = ( $args{vol} ) ? $args{vol} : 1.0;

        my @dst = map {
            sin( 2.0 * pi * $_ ) * $vol;
        } @{$args{pitch}};

        return \@dst;
    };
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
