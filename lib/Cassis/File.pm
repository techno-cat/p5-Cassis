package Cassis::File;

use strict;
use warnings;

sub write {
    my %args = @_;

    if ( not exists $args{file}     ) { die 'file parameter is required.';     }
    if ( not exists $args{channels} ) { die 'channels parameter is required.'; }

    if ( scalar(@{$args{channels}}) != 1 ) {
        die 'Sorry, supports monaural only.'
    }

    my $raw = ( exists $args{raw} ) ? $args{raw} : 0;
    my $samples_per_sec = ( exists $args{fs} ) ? $args{fs} : 44100;
    my $bits_per_sample = ( exists $args{bits} ) ? $args{bits} : 16;

    if ( $bits_per_sample == 8 or $bits_per_sample == 16 ) {
        # ok!
    }
    else {
        die 'Supported bits is 8 or 16.'
    }

    my $file_name = $args{file};
    my $samples_ref = $args{channels}->[0];

    my $block_size = $bits_per_sample / 8;
    my $size = scalar(@{$samples_ref}) * $block_size;
    my $bytes_per_sec = $block_size * $samples_per_sec;
    my $header =
          'RIFF'                        # ChunkID
        . pack('L', ($size + 36))       # ChunkSize
        . 'WAVE';                       # FormType
    my $fmt_chunk =
          'fmt '                        # ChunkID
        . pack('L', 16)                 # ChunkSize
        . pack('S', 1)                  # WaveFormatType
        . pack('S', 1)                  # Channel
        . pack('L', $samples_per_sec)   # SamplesPerSec
        . pack('L', $bytes_per_sec)     # BytesPerSec
        . pack('S', $block_size)        # BlockSize
        . pack('S', $bits_per_sample);  # BitsPerSample
    my $data_chunk =
          'data'                        # ChunkID
        . pack('L', $size);             # ChunkSize

    open( my $fh, '>', $file_name ) or die;
    binmode $fh;
    print $fh ($header . $fmt_chunk . $data_chunk);
    if ( $bits_per_sample == 16 ) {
        if ( $raw ) {
            print $fh pack( 's*', @{$samples_ref} );
        }
        else {
            foreach my $sample (@{$samples_ref}) {
                print $fh pack( 's', int($sample * 32767.0) );
            }
        }
    }
    else {
        if ( $raw ) {
            print $fh pack( 'c*', @{$samples_ref} );
        }
        else {
            foreach my $sample (@{$samples_ref}) {
                print $fh pack( 'c', int($sample * 127.0) );
            }
        }
    }
    close $fh;
}

1;

__END__

=encoding utf-8

=head1 NAME

Cassis::File - Wave File IO

=head1 SYNOPSIS

    use Cassis::File;
    use Math::Trig ':pi';

    # Sin Wave
    my $pitch = 44100 / 440;
    my @samples = map { sin((2.0 * pi) * $_ / $pitch); } 0..(44100 - 1);

    Cassis::File::write( file => 'sin.wav', channels => [ \@samples ] );

=head1 DESCRIPTION

    now working...

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
