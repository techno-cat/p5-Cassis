package Cassis::EG;
use strict;
use warnings;
use List::Util qw(min);

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{fs} ) { die 'fs parameter is required.'; }
    if ( $args{fs} <= 0 ) { die 'fs parameter must be greater than 0.'; }

    my $ret = bless {
        fs       => $args{fs},
        t        => 0,
        adsr     => [ 0.0, 0.0, 1.0, 0.0 ],
        curve    => 1.0,
        gatetime => 0.0,
        last_value => 0.0
    }, $class;

    $ret->set_adsr( $args{adsr} ) if ( exists $args{adsr} );
    $ret->set_curve( $args{curve} ) if ( exists $args{curve} );

    $ret;
}

sub set_adsr {
    my ( $self, $adsr ) = @_;

    if ( scalar(@{$adsr}) != 4 ) {
        die 'adsr parameter must contain 4 parameters.';
    }

    my ( $attack, $decay, $sustain, $release ) = @{$adsr};

    if ( $attack < 0.0 ) {
        warn "Attack is clipped. ($attack -> 0)";
        $attack = 0.0;
    }

    if ( $decay < 0.0 ) {
        warn "Decay is clipped. ($decay -> 0)";
        $decay = 0.0;
    }

    if ( $sustain < 0.0 ) {
        warn "Sustain is clipped. ($sustain -> 0)";
        $sustain = 0.0;
    }

    if ( $release < 0.0 ) {
        warn "Release is clipped. ($release -> 0)";
        $release = 0.0;
    }

    $self->{adsr} = [ $attack, $decay, $sustain, $release ];
}

sub adsr {
    $_[0]->{adsr};
}

sub set_curve {
    my ( $self, $curve ) = @_;

    if ( $curve < 0.0 ) {
        warn "curve is clipped. ($curve -> 0)";
        $curve = 0.0;
    }

    $self->{curve} = $curve;
}

sub curve {
    $_[0]->{curve};
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{num} ) { die 'num parameter is required.'; }

    my ( $attack, $decay, $release ) = map {
        int( $self->{adsr}->[$_] * $self->{fs} );
    } ( 0, 1, 3 );
    my $sustain = $self->{adsr}->[2];
    my $gatetime = int( $self->{gatetime} * $self->{fs} );

    my ( $t, $curve ) = ( $self->{t}, $self->{curve} );

    my @dst = ();
    my $n = min( $gatetime, $args{num} );
    if ( $t < $gatetime ) {

        my $th = $attack;
        while ( $t < $th and scalar(@dst) < $n ) {
            my $wk = ($t / $attack) ** $curve;
            push @dst, $wk;
            $t++;
        }

        $th += $decay;
        while ( $t < $th and scalar(@dst) < $n ) {
            my $wk = (($t - $attack) / $decay) ** $curve;
            push @dst, (1.0 - ((1.0 - $sustain) * $wk));
            $t++;
        }

        while ( scalar(@dst) < $n ) {
            push @dst, $sustain;
            $t++;
        }

        $self->{last_value} = $dst[-1] if ( @dst );
    }

    $n = $args{num};
    if ( scalar(@dst) < $n ) {

        my $th = $gatetime + $release;
        while ( $t < $th and scalar(@dst) < $n ) {
            my $wk = 1.0 - ((($t - $gatetime) / $release) ** $curve);
            push @dst, ($self->{last_value} * $wk);
            $t++;
        }

        while ( scalar(@dst) < $n ) {
            push @dst, 0.0;
            $t++;
        }
    }

    $self->{t} = $t;

    return \@dst;
}

sub one_shot {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{gatetime} ) { die 'gatetime parameter is required.'; }

    $self->trigger( gatetime => $args{gatetime} );

    my $gatetime = int( $args{gatetime} * $self->{fs} );
    my $release = int( $self->{adsr}->[3] * $self->{fs} );

    return $self->exec( num => ($gatetime + $release + 1) );
}

sub trigger {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{gatetime} ) {
        warn 'gatetime parameter not exists.'
    }

    my $gatetime = ( exists $args{gatetime} ) ? $args{gatetime} : 0.0;
    if ( $gatetime < 0.0 ) {
        warn "gatetime is clipped. ($gatetime -> 0)";
        $gatetime = 0.0;
    }

    ( $self->{t}, $self->{gatetime} ) = ( 0, $gatetime );
}

sub hold {
    my $self = shift;
    ( $self->{t} < int($self->{gatetime} * $self->{fs}) ) ? 1 : 0;
}

1;

__END__

=encoding utf-8

=head1 NAME

Cassis::EG - Envelop Genarator

=head1 SYNOPSIS

    use Cassis::EG;
    
    my $envelop = Cassis::EG->new( fs => 44100, adsr => [ 0.1, 0.2, 1.0, 0.5 ] );
    my $dst = $envelop->exec( num => 44100 ); # 1sec

=head1 DESCRIPTION

=over

=item new()

"fs" is required, "fs" is sampling rate.

    #   Attack  Decay
    # <---------><->
    #           /\
    #         /   \
    #       /      \___________
    #     /         A           \
    #   /           | Sustain     \
    # /             V               \_______
    # <-----------------------><---->
    #          Gate Time      Release
    
    my $envelop = Cassis::EG->new(
        fs => 44100, # sampling-rate
        adsr => [
            0.1,     # Attack : time(sec)
            0.2,     # Decay  : time(sec)
            1.0,     # Sustain: gain
            0.5      # Release: time(sec)
        ],
        curve => 2.0 # default: 1.0 (= Linear)
    );

=item set_adsr()

    # Set ADSR.
    my $new_adsr = [
        0.2,    # Attack(sec)  : ( 0.0 <= value )
        0.1,    # Decay(sec)   : ( 0.0 <= value )
        0.8,    # Sustain      : ( 0.0 <= value )
        0.5     # Release(sec) : ( 0.0 <= value )
    ];
    $envelop->set_adsr( $new_adsr );

=item adsr()

    # Get ADSR. See also "set_adsr()".
    my $adsr = $dca->adsr();

=item set_curve()

    # Set curve.
    my $new_curve = 1.0; # ( 0.0 <= value )
    $envelop->set_curve( $new_curve );

=item curve()

    # Get curve.
    my $curve = $envelop->curve();

=item on()

    # Like note on.
    $envelop->on();

=item off()

    # Like note off.
    $envelop->off();

=item hold()

    my $envelop = Cassis::EG->new( ... );
    $envelop->hold(); # => 0
    $envelop->on();
    $envelop->hold(); # => 1
    $envelop->off();
    $envelop->hold(); # => 0

=item exec()

    # Get envelop.
    $envelop->on();
    my $dst1 = $envelop->exec( num => 44100 );
    $envelop->off();
    my $dst2 = $envelop->exec( num => 44100 );

=item one_shot()

    # Get envelop for the duration.
    my $dst = $envelop->one_shot(
        gatetime => 1.0 # time(sec)
    );

=back

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
