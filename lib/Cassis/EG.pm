package Cassis::EG;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;

    if ( not exists $args{fs} ) { die 'fs parameter is required.'; }
    if ( $args{fs} <= 0 ) { die 'fs parameter must be greater than 0.'; }

    my $adsr = ( exists $args{adsr} ) ? $args{adsr} : [ 0.0, 0.0, 1.0, 0.0 ];
    my ( $attack, $decay, $sustain, $release ) = _to_valid_adsr( $adsr );

    bless {
        fs    => $args{fs},
        t     => 0,
        adsr  => [ $attack, $decay, $sustain, $release ],
        curve => ( exists $args{curve} ) ? _to_valid_curve($args{curve}) : exp(1),
        hold  => 0,
        last_value => 0.0
    }, $class;
}

sub curve {
    $_[0]->{curve};
}

sub set_curve {
    my ( $self, $curve ) = @_;

    $self->{curve} = _to_valid_curve( $curve );
}

sub adsr {
    $_[0]->{adsr};
}

sub set_adsr {
    my ( $self, $adsr ) = @_;

    my ( $attack, $decay, $sustain, $release ) = _to_valid_adsr( $adsr );
    $self->{adsr} = [ $attack, $decay, $sustain, $release ];
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{num} ) { die 'num parameter is required.'; }

    my ( $attack, $decay, $release ) = map {
        int( $self->{adsr}->[$_] * $self->{fs} );
    } ( 0, 1, 3 );
    my $sustain = $self->{adsr}->[2];
    my @dst = ();

    my ( $t, $curve ) = ( $self->{t}, $self->{curve} );
    if ( $self->{hold} ) {

        my $th = $attack;
        while ( $t < $th and scalar(@dst) < $args{num} ) {
            my $wk = ($t / $attack) ** $curve;
            push @dst, $wk;
            $t++;
        }

        $th += $decay;
        while ( $t < $th and scalar(@dst) < $args{num} ) {
            my $wk = (($t - $attack) / $decay) ** $curve;
            push @dst, (1.0 - ((1.0 - $sustain) * $wk));
            $t++;
        }

        while ( scalar(@dst) < $args{num} ) {
            push @dst, $sustain;
        }

        $self->{last_value} = $dst[-1] if ( @dst );
    }
    else {

        while ( $t < $release and scalar(@dst) < $args{num} ) {
            my $wk = (($release - $t) / $release) ** $curve;
            push @dst, ($self->{last_value} * $wk);
            $t++;
        }

        while ( scalar(@dst) < $args{num} ) {
            push @dst, 0.0;
        }
    }

    $self->{t} = $t;

    return \@dst;
}

sub one_shot {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{gatetime} ) { die 'gatetime parameter is required.'; }

    my $gatetime = int( $args{gatetime} * $self->{fs} );
    my $release = int( $self->{adsr}->[3] * $self->{fs} );

    $self->on();
    my $dst1 = $self->exec( num => $gatetime );
    $self->off();
    my $dst2 = $self->exec( num => $release + 1 );

    push @{$dst1}, @{$dst2};
    return $dst1;
}

sub on {
    $_[0]->{t} = 0;
    $_[0]->{hold} = 1;
}

sub off {
    $_[0]->{t} = 0;
    $_[0]->{hold} = 0;
}

sub hold {
    $_[0]->{hold};
}

sub _to_valid_adsr {
    my $adsr = shift;

    if ( scalar(@{$adsr}) != 4 ) {
        die 'adsr parameter must contain 4 parameters.';
    }

    my ( $attack, $decay, $sustain, $release ) = @{$adsr};

    if ( $attack < 0.0 ) {
        warn "Attack is clipped. ($attack => 0)";
        $attack = 0.0;
    }

    if ( $decay < 0.0 ) {
        warn "Decay is clipped. ($decay => 0)";
        $decay = 0.0;
    }

    if ( $sustain < 0.0 ) {
        warn "Sustain is clipped. ($sustain => 0)";
        $sustain = 0.0;
    }

    if ( $release < 0.0 ) {
        warn "Release is clipped. ($release => 0)";
        $release = 0.0;
    }

    return ( $attack, $decay, $sustain, $release );
}

sub _to_valid_curve {
    my $curve = shift;

    if ( $curve < 0.0 ) {
        warn "curve is clipped. ($curve => 0)";
        $curve = 0.0;
    }

    return $curve;
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
    
    # "fs" is required.
    my $envelop = Cassis::EG->new(
        fs => 44100, # sampling-rate
        adsr => [
            0.1,     # Attack : time(sec)
            0.2,     # Decay  : time(sec)
            1.0,     # Sustain: gain
            0.5      # Release: time(sec)
        ],
        curve => 2.0 # default: exp^1(= 2.718...)
    );

=item adsr()

    # Get ADSR. See also "set_adsr()".
    my $adsr = $dca->adsr();

=item set_adsr()

    # Set ADSR.
    my $new_adsr = [ 0.2, 0.1, 0.8, 0.5 ];
    $envelop->set_adsr( $new_adsr );

=item curve()

    # Get curve.
    my $curve = $envelop->curve();

=item set_curve()

    # Set curve.
    my $new_curve = 1.0;
    $envelop->set_curve( $new_curve );

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
