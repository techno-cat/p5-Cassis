package Cassis;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Cassis::Dco;
use Cassis::Osc;
use Cassis::Amp;
use Cassis::EG;
use Cassis::Iir2;
use Cassis::File;

1;
__END__

=encoding utf-8

=head1 NAME

Cassis - Synthesizer Modules

=head1 SYNOPSIS

    package MySynth;
    use strict;
    use warnings;
    use Cassis;
    
    sub new {
        my $class = shift;
        my %args = @_;
    
        my $fs = ( exists $args{fs} ) ? $args{fs} : 44100;
        bless {
            samples => [],
            fs      => $fs,
            dco     => Cassis::Dco->new( fs => $fs )
        }, $class;
    }
    
    sub exec {
        my $self = shift;
        my %args = @_;
    
        my $dst = $self->{dco}->exec( num => $args{num} );
        push @{$self->{samples}}, @{$dst};
    }
    
    sub write {
        my $self = shift;
        my %args = @_;
    
        $args{fs}       = $self->{fs};
        $args{channels} = [ $self->{samples} ];
    
        Cassis::File::write( %args );
    }
    
    package main;
    use strict;
    use warnings;
    
    my $s = MySynth->new();
    $s->exec( num => 44100 );
    $s->write( file => 'sample.wav' );

=head1 DESCRIPTION

    Modules for generating a short sound.

=head2 Overview of documentation

=over 4

=item *

Cassis - This document.

=item *

Cassis::Dco - Digital Controlled Oscillator.

=item *

Cassis::Osc - Oscillator.

=item *

Cassis::Amp - Amplifier Section.

=item *

Cassis::EG - Envelop Genarator.

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

