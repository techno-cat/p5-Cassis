#!perl
use strict;
use warnings;

use Cassis;
use Imager;

use constant TICK_COLOR => Imager::Color->new( 80, 80, 80 );
use constant TICK_X => 150;
use constant TICK_Y => 200;

my @src = map { ($_ % 300) < 150 ? +.5 : -.5 } 0..599;

my $cutoff = 0.01;
my $q = 1.0 / sqrt(2.0);

{
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );
    my $dst = $f->exec( src => \@src, params => $f->calc_lpf_params() );
    draw_graph( 'graph_lpf.png', \@src, $dst );
}

{
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );
    my $dst = $f->exec( src => \@src, params => $f->calc_hpf_params() );
    draw_graph( 'graph_hpf.png', \@src, $dst );
}

{
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );
    my $dst = $f->exec( src => \@src, params => $f->calc_bpf_params() );
    draw_graph( 'graph_bpf.png', \@src, $dst );
}

{
    my $f = Cassis::Iir2->new( cutoff => $cutoff, q => $q );
    my $dst = $f->exec( src => \@src, params => $f->calc_bef_params() );
    draw_graph( 'graph_bef.png', \@src, $dst );
}

sub draw_graph {
    my ( $path, $src, $dst ) = @_;

    my $img = Imager->new(
        xsize => scalar(@{$src}), ysize => int(TICK_Y * 2.0) + 1 );
    $img->box( filled => 1, color => 'black' );
    draw_graduation( $img, TICK_COLOR );

    draw_wave( $img, \@src, 'red' );
    draw_wave( $img, $dst, 'green' );

    $img->write( file => $path ) or die $img->errstr;
}

sub draw_graduation {
    my ( $img, $color ) = @_;

    my $y0 = int($img->getheight() / 2);
    my $w = $img->getwidth();
    my $h = $img->getheight();

    my $x = 0;
    while ( $x < $w ) {
        $img->line( color => $color,
            x1 => $x, y1 => 0,
            x2 => $x, y2 => $h - 1 );
        $x += TICK_X;
    }

    $img->line( color => $color,
        x1 => 0,      y1 => $y0,
        x2 => $w - 1, y2 => $y0 );
}

sub draw_wave {
    my ( $img, $data, $color ) = @_;
    my $y0 = int($img->getheight() / 2);

    my $xmax = scalar(@{$data}) - 1;
    my @points = map {
        my $gain = TICK_Y * $data->[$_];
        [ $_, $y0 - int(($gain < .0) ? ($gain - .5) : ($gain + .5)) ];
    } 0..$xmax;

    $img->polyline( points => \@points, color => $color );
}

=encoding utf-8

=head1 NAME

simple_filtering.pl - Simple Filtering

=head1 SYNOPSIS

    $ perl simple_filtering.pl

=head1 DESCRIPTION

    This is a sample script.

=head1 DEPENDENCIES

    Imager

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
