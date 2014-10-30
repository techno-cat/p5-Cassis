# NAME

Cassis - Synthesizer Modules

# SYNOPSIS

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
            dco     => Cassis::DCO->new( fs => $fs )
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

# DESCRIPTION

    Synthesizer Modules for generating a short sound.

## Overview of documentation

- Cassis - This document.
- Cassis::DCO - Digital Controlled Oscillator.
- Cassis::Osc - Oscillator.
- Cassis::Noise - Noise Genarator.
- Cassis::Mixer - Mixer Section.
- Cassis::Amp - Amplifier Section.
- Cassis::EG - Envelope Genarator.
- Cassis::Iir2 - Second-order IIR digital filter.
- Cassis::File - Wave File IO.

# LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

neko <techno.cat.miau@gmail.com>
