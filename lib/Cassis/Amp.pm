package Cassis::Amp;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;

    bless {
        volume => ( exists $args{volume} ) ? $args{volume} : 1.0
    }, $class;
}

sub volume {
    $_[0]->{volume};
}

sub set_volume {
    $_[0]->{volume} = $_[1];
}

sub exec {
    my $self = shift;
    my %args = @_;

    if ( not exists $args{src} ) { die 'src parameter is required.'; }

    my @dst = ();
    if ( exists $args{mod_volume} ) {
        my @mod_src = ( exists $args{mod_volume}->{src} ) ? @{$args{mod_volume}->{src}} : ();
        my $mod_depth = ( exists $args{mod_volume}->{depth} ) ? $args{mod_volume}->{depth} : 1.0;

        if ( scalar($args{src}) < scalar(@mod_src) ) {
            warn 'Modulation source is shorter than input.';
            while ( scalar(@mod_src) < scalar($args{src}) ) { push @mod_src, 0.0; }
        }

        my $mod_range = $self->{volume} * $mod_depth;
        my $volume0 = $self->{volume} - $mod_range;
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
    my $amp = Cassis::Amp::new();
    my $amp = Cassis::Amp::new( volume => 0.8 );

=item volume()

    # Get volume.
    my $volume = $amp->volume();

=item set_volume()

    # Set volume.
    $amp->set_volume( $new_volume );

=item exec()

    # Get amplification result.
    $amp->set_volume( 2.0 );
    my $dst = $amp->exec( src => [ 1, 2, 3 ] ); # => [ 2, 4, 6 ]
    
    # Amplification with modulation.
    $amp->set_volume( 1.0 );
    my $dst = $amp->exec(
        src => [ 1, 2, 3 ],
        mod_volume => {
            src => [ -1, 0, +1 ], depth => 1.0
        }
    ); # => [ 0, 1, 3 ];
    
    my $dst = $amp->exec( src => [ 1, 2, 3 ] ); # => [ 2, 4, 6 ]

=back

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
