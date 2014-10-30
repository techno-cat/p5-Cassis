package Cassis::Mixer;
use strict;
use warnings;
use List::Util qw(max);

sub mix {
    my @channels = @_;

    if ( scalar(@channels) == 0 ) { die 'Mixing source not exists.'; }

    my $n = max( map {
        scalar(@{$_->{src}});
    } @channels );

    my @dst = map { 0.0; } 0..($n - 1);

    my $ch_idx = 0;
    foreach my $ch ( @channels ) {
        if ( not exists $ch->{src}    ) { die "src parameter not exists. (at $ch_idx)";    }
        if ( not exists $ch->{volume} ) { die "volume parameter not exists. (at $ch_idx)"; }

        my $vol = $ch->{volume};
        my @src = map {
            $_ * $vol;
        } @{$ch->{src}};

        if ( scalar(@src) < $n ) {
            warn "source is shorter than other. (at $ch_idx)";
        }

        my $i = 0;
        foreach ( @src ) {
            $dst[$i++] += $_;
        }

        $ch_idx++;
    }

    return \@dst;
}

1;

__END__

=encoding utf-8

=head1 NAME

Cassis::Mixer - Mixer Section

=head1 SYNOPSIS

    use Cassis::Mixer;
    
    Cassis::Mixer::mix(
        { src => [ 1, 2, 3 ], volume => 0.5 },
        { src => [ 2, 3, 4 ], volume => 0.6 },
        { src => [ 3, 4, 5 ], volume => 0.3 }
    );

=head1 DESCRIPTION

=over

=item mix()

    # Using as amplifier.
    Cassis::Mixer::mix(
        { src => [ 1, 2, 3 ], volume => 0.5 }
    ); # => [ 0.5, 1.0, 1.5 ]

    # Get mixing result.
    Cassis::Mixer::mix(
        { src => [ 1, 2, 3 ], volume => 0.5 },
        { src => [ 3, 4, 5 ], volume => 0.5 }
    ); # => [ 2, 3, 4 ]

=back

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
