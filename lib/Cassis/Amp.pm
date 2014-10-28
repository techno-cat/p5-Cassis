package Cassis::Amp;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;

    my $ret = bless {
        volume => 1.0
    }, $class;

    $ret->set_volume( $args{volume} ) if ( exists $args{volume} );

    $ret;
}

sub set_volume {
    my ( $self, $volume ) = @_;

    if ( $volume < 0.0 ) {
        warn "volume is clipped. ($volume -> 0)";
        $volume = 0.0;
    }

    $self->{volume} = $volume;
}

sub volume {
    $_[0]->{volume};
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    my @dst = ();
    if ( exists $args{mod_volume} ) {
        my @mod_src = ( exists $args{mod_volume}->{src} ) ? @{$args{mod_volume}->{src}} : ();
        my $mod_depth = ( exists $args{mod_volume}->{depth} ) ? $args{mod_volume}->{depth} : 1.0;

        if ( scalar(@mod_src) < scalar(@{$args{src}}) ) {
            warn 'Modulation source is shorter than input.';
            while ( scalar(@mod_src) < scalar(@{$args{src}}) ) { push @mod_src, 0.0; }
        }

        my $mod_range = $self->{volume} * $mod_depth;
        my $volume0 = $self->{volume} - abs($mod_range);
        @dst = map {
            my $volume = $volume0 + (shift(@mod_src) * $mod_range);
            $_ * (( $volume < 0.0 ) ? 0.0 : $volume);
        } @{$args{src}};
    }
    else {
        my $volume = ( $self->{volume} < 0.0 ) ? 0.0 : $self->{volume};
        @dst = map {
            $_ * $volume;
        } @{$args{src}};
    }

    return \@dst;
}

1;

__END__

=encoding utf-8

=head1 NAME

Cassis::Amp - Amplifier Section

=head1 SYNOPSIS

    use Cassis::Amp;
    
    my $amp = Cassis::Amp->new( volume => 0.8 );
    my $dst = $osc->exec( src => [ 1, 2, 3 ] );

=head1 DESCRIPTION

=over

=item new()

    # "volume" is amplification factor.
    my $amp = Cassis::Amp::new(); # volume is 1.0.
    my $amp = Cassis::Amp::new( volume => 0.8 );

=item set_volume()

    # Set volume.
    my $new_volume = 0.5; # ( 0.0 <= value )
    $amp->set_volume( $new_volume );

=item volume()

    # Get volume.
    my $volume = $amp->volume();

=item exec()

    # Get amplification result.
    $amp->set_volume( 2.0 );
    my $dst = $amp->exec( src => [ 1, 2, 3 ] ); # => [ 2, 4, 6 ]
    
    # Amplification with modulation.
    $amp->set_volume( 1.0 );
    my $dst = $amp->exec(
        src => [ 2, 2, 2 ],
        mod_volume => {
            src => [ -1, 0, +1 ], depth => 0.5
        }
    ); # => [ 0, 1, 2 ];

=back

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
