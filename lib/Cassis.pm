package Cassis;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

our $SAMPLING_RATE = 44100;
our $BIT_DEPTH = 16;

use Cassis::Iir2;
use Cassis::File;

sub new {
    my $class = shift;
    my %args = @_;

    bless {
        samples => ( exists $args{samples} ) ? $args{samples} : [],
        sf      => ( exists $args{sf} ) ? $args{sf} : $SAMPLING_RATE,
        bits    => ( exists $args{bits} ) ? $args{bits} : $BIT_DEPTH
    }, $class;
}

sub samples {
    return $_[0]->{samples};
}

sub append {
    return push @{$_[0]->{samples}}, @{$_[1]};
}

sub write {
    my $self = shift;
    my %args = @_;

    $args{sf} = $self->{sf};
    $args{bits} = $self->{bits};
    $args{channels} = [ $self->{samples} ];

    Cassis::File::write( %args );
}

1;
__END__

=encoding utf-8

=head1 NAME

Cassis - Synthesizer modules

=head1 SYNOPSIS

    use Cassis;

    now working ...

=head1 DESCRIPTION

    Modules for generating a short sound.

=head2 Overview of documentation

=over 4

=item *

Cassis - This document.

=item *

Cassis::Iir2 - Second-order IIR digital filter.

=item *

Cassis::File - Wave File IO.

=back

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut

