package Cassis::Noise;
use strict;
use warnings;

our $NOISE_FUNC = sub {
    srand( 2 );
    my @noise = map { rand( 2.0 ) - 1.0; } 1..50000;

    return \@noise;
};

sub new {
    my $class = shift;
    my %args = @_;

    my $ret =  bless {
        noise => ( exists $args{noise} ) ? $args{noise} : $NOISE_FUNC->(),
        t     => 0,
        speed => 1.0
    }, $class;

    $ret->set_speed( $args{speed} ) if ( exists $args{speed} );

    $ret;
}

sub set_speed {
    my ( $self, $speed ) = @_;

   if ( $speed < 0.0 ) {
        warn "speed is clipped. ($speed -> 0)";
        $speed = 0.0;
    }

    $self->{speed} = $speed;
}

sub speed {
    $_[0]->{speed};
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{num} ) { die 'num parameter is required.'; }

    my @dst = ();
    my ( $t, $noise ) =  ( $self->{t}, $self->{noise} );
    my $noise_size = scalar(@{$noise});
    if ( exists $args{mod_speed} ) {
        my @mod_src = ( exists $args{mod_speed}->{src} ) ? @{$args{mod_speed}->{src}} : ();
        my $mod_depth = ( exists $args{mod_speed}->{depth} ) ? $args{mod_speed}->{depth} : 1.0;

        if ( scalar(@mod_src) < $args{num} ) {
            warn 'Modulation source is shorter than input.';
            while ( scalar(@mod_src) < $args{num} ) { push @mod_src, 0.0; }
        }

        my $mod_range = ($self->{speed} / $noise_size) * $mod_depth;
        my $speed0 = ($self->{speed} / $noise_size) - abs($mod_range);
        @dst = map {
            my $w = $t - int($t);
            $t += ( $speed0 + ($_ * $mod_range) );
            $noise->[int($noise_size * $w)];
        } @mod_src;
    }
    else {
        my $speed = $self->{speed} / $noise_size;
        @dst = map {
            my $w = $t - int($t);
            $t += $speed;
            $noise->[int($noise_size * $w)];
        } 1..$args{num};
    }

    $self->{t} = $t;

    return \@dst;
}

1;

__END__

=encoding utf-8

=head1 NAME

Cassis::Noise - Noise Genarator

=head1 SYNOPSIS

    use Cassis::Noise;
    
    my $noise = Cassis::Noise->new();
    my $dst = $noise->exec( num => 44100 );

=head1 DESCRIPTION

=over

=item new()

This module is not what is called "Noise Generator".
Noise data by a random number from -1.0 to +1.0, will be prepared in advance.

    my $noise = Cassis::Noise->new();
    
    # When "speed" is less than 1.0, it will be sampling & hold.
    my $noise = Cassis::Noise->new(
        speed => 0.001,
    );

    # If you want to use your noise.
    my $noise = Cassis::Noise->new(
        noise => [ 1..10000 ]
    );

=item set_speed()

    # Set speed.
    my $new_speed = 2.0;
    $noise->set_speed( $new_speed );

=item speed()

    # Get speed.
    my $speed = $noise->speed();

=item exec()

    # Genarate noise.
    my $dst = $noise->exec( num => 10 );
    
    # Genarate with modulation.
    my $dst = $noise->exec(
        num => 10,
        mod_speed => {
            src => [ -1, -2, -3, -4, -5, -1, -2, -3, -4, -5 ],
            depth => 0.1
        }
    } );

=back

=head2 our $NOISE_FUNC

If you want to use your noise, there is another way.

    # change like this.
    use Math::Random::NormalDistribution;
    local $Cassis::Noise::NOISE_FUNC = sub {
        my $gen = rand_nd_generator( 0.0, 0.5 );
        my @noise = map { $gen->() } 1..50000;
    
        return \@noise;
    };

=head1 SEE ALSO

    Math::Random::NormalDistribution

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
